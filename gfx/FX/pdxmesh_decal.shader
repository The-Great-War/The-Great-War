Includes = {
	"cw/shadow.fxh"
	"cw/terrain.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_decals.fxh"
	"jomini/jomini_province_overlays.fxh"
	"dynamic_masks.fxh"
	"distance_fog.fxh"
	"coloroverlay.fxh"
	"fog_of_war.fxh"
}

PixelShader =
{
	TextureSampler DiffuseTexture
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler PropertiesTexture
	{
		Ref = PdxTexture1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler NormalTexture
	{
		Ref = PdxTexture2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler EnvironmentMap
	{
		Ref = JominiEnvironmentMap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		Type = "Cube"
	}
	TextureSampler ShadowTexture
	{
		Ref = PdxShadowmap
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		CompareFunction = less_equal
		SamplerType = "Compare"
	}
}

VertexShader =
{
	MainCode VS_decal_standard
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT Out = ConvertOutput( PdxMeshVertexShaderStandard( Input ) );
				Out.InstanceIndex = Input.InstanceIndices.y;

				Out.WorldSpacePos.y = GetHeight( Out.WorldSpacePos.xz );
				Out.WorldSpacePos.y += 0.01;
				#ifdef DECAL_LOCAL
					Out.WorldSpacePos.y += 0.01;
				#endif

				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos.xyz, 1.0 ) );

				return Out;
			}
		]]
	}

	MainCode VS_decal_mapobject
	{
		Input = "VS_INPUT_PDXMESH_MAPOBJECT"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				float4x4 WorldMatrix = UnpackAndGetMapObjectWorldMatrix( Input.InstanceIndex24_Opacity8 );
				VS_OUTPUT Out = ConvertOutput( PdxMeshVertexShader( PdxMeshConvertInput( Input ), 0, WorldMatrix ) );
				Out.InstanceIndex = Input.InstanceIndex24_Opacity8;

				Out.WorldSpacePos.y = GetHeight( Out.WorldSpacePos.xz );
				Out.WorldSpacePos.y += 0.01;
				#ifdef DECAL_LOCAL
					Out.WorldSpacePos.y += 0.01;
				#endif

				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos.xyz, 1.0 ) );

				return Out;
			}
		]]
	}
}

PixelShader =
{
	Code
	[[
		float4 CalcDecal( float2 UV, float3 Bitangent, float3 WorldSpacePos, float4 Diffuse, float Alpha )
		{
			float2 MapCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			float2 ProvinceCoords = WorldSpacePos.xz / _ProvinceMapSize;

			float4 Properties = PdxTex2D( PropertiesTexture, UV );
			float4 NormalPacked = PdxTex2D( NormalTexture, UV );
			float3 NormalSample = UnpackRRxGNormal( NormalPacked );

			// Alpha blend two sources
			Diffuse.a = CalcHeightBlendFactors( float4( Diffuse.a, 0.3, 0.0, 0.0 ), float4( Alpha, 1.0 - Alpha, 0.0, 0.0 ), 0.25 ).r;

			// Devastation
			ApplyDevastationDecal( Diffuse, WorldSpacePos.xz, 1.0 - Properties.r );

			float3 Normal = CalculateNormal( WorldSpacePos.xz );
			#ifdef TANGENT_SPACE_NORMALS
				float3 Tangent = cross( Bitangent, Normal );
				float3x3 TBN = Create3x3( normalize( Tangent ), normalize( Bitangent ), Normal );
				Normal = normalize( mul( NormalSample, TBN ) );
			#else
				Normal = ReorientNormal( Normal, NormalSample );
			#endif

			float3 ColorMap = PdxTex2D( ColorTexture, float2( MapCoords.x, 1.0 - MapCoords.y ) ).rgb;
			Diffuse.rgb = SoftLight( Diffuse.rgb, ColorMap, ( 1.0 - Properties.r ) );

			// Color overlay pre light
			#if !defined( NO_COLOROVERLAY ) && !defined( GUI_SHADER )
				float3 ColorOverlay;
				float PreLightingBlend;
				float PostLightingBlend;
				GameProvinceOverlayAndBlend( ProvinceCoords, WorldSpacePos, ColorOverlay, PreLightingBlend, PostLightingBlend );
				Diffuse.rgb = ApplyColorOverlay( Diffuse.rgb, ColorOverlay, PreLightingBlend );
			#endif

			// Light
			Properties.a = ScaleRoughnessByDistance( Properties.a, WorldSpacePos );
			SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal, Properties.a, Properties.g, Properties.b );
			SLightingProperties LightingProps = GetSunLightingProperties( WorldSpacePos, ShadowTexture );
			#ifndef LOW_QUALITY_SHADERS
				Diffuse.rgb = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );
			#endif

			// Color overlay post light
			#if !defined( UNDERWATER) && !defined( NO_COLOROVERLAY ) && !defined( GUI_SHADER )
				Diffuse.rgb = ApplyColorOverlay( Diffuse.rgb, ColorOverlay, PostLightingBlend );
				Diffuse.rgb = ApplyFogOfWar( Diffuse.rgb, WorldSpacePos );
				Diffuse.rgb = GameApplyDistanceFog( Diffuse.rgb, WorldSpacePos );
			#endif

			// Province Highlight
			#if !defined( NO_COLOROVERLAY ) && !defined( GUI_SHADER )
				Diffuse.rgb = ApplyHighlight( Diffuse.rgb, ProvinceCoords );
			#endif

			DebugReturn( Diffuse.rgb, MaterialProps, LightingProps, EnvironmentMap );
			return Diffuse;
		}
	]]

	MainCode PS_world
	{
		TextureSampler DecalAlphaTexture
		{
			Ref = PdxTexture3
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "Linear"
			SampleModeU = "Clamp"
			SampleModeV = "Clamp"
		}

		Input = "VS_OUTPUT"
		Output = "PDX_COLOR"
		Code
		[[
			static const float DECAL_TILING_SCALE = 0.5;
			static const float DECAL_TILING_1024_SCALE = 0.125;

			PDX_MAIN
			{
				float Alpha = PdxTex2D( DecalAlphaTexture, Input.UV0 ).r;
				Alpha = PdxMeshApplyOpacity( Alpha, Input.Position.xy, GetOpacity( Input.InstanceIndex ) );


				float2 DetailUV = Input.WorldSpacePos.xz;
				#if defined( TILING_1024 )
					DetailUV *= float2( DECAL_TILING_1024_SCALE, -DECAL_TILING_1024_SCALE );
				#else
					DetailUV *= float2( DECAL_TILING_SCALE, -DECAL_TILING_SCALE );
				#endif

				float4 Diffuse = PdxTex2D( DiffuseTexture, DetailUV );
				Diffuse = CalcDecal( DetailUV, Input.Bitangent, Input.WorldSpacePos, Diffuse, Alpha );

				return float4( Diffuse.rgb, Diffuse.a );
			}
		]]
	}

	MainCode PS_local
	{
		Input = "VS_OUTPUT"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float4 Diffuse = PdxTex2D( DiffuseTexture, Input.UV0 );
				Diffuse.a = PdxMeshApplyOpacity( Diffuse.a, Input.Position.xy, GetOpacity( Input.InstanceIndex ) );

				Diffuse = CalcDecal( Input.UV0, Input.Bitangent, Input.WorldSpacePos, Diffuse, 0.5 );

				return float4( Diffuse.rgb, Diffuse.a );
			}
		]]
	}
}

RasterizerState RasterizerState
{
	DepthBias = 0
	SlopeScaleDepthBias = 0
}

Effect decal_world
{
	VertexShader = "VS_decal_standard"
	PixelShader = "PS_world"
}

Effect decal_world_mapobject
{
	VertexShader = "VS_decal_mapobject"
	PixelShader = "PS_world"
}

Effect decal_local
{
	VertexShader = "VS_decal_standard"
	PixelShader = "PS_local"

	Defines = { "TANGENT_SPACE_NORMALS" "DECAL_LOCAL" }
}

Effect decal_local_mapobject
{
	VertexShader = "VS_decal_mapobject"
	PixelShader = "PS_local"

	Defines = { "TANGENT_SPACE_NORMALS" "DECAL_LOCAL" }
}
