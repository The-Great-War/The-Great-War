Includes = {
	"cw/pdxmesh.fxh"
	"cw/terrain.fxh"
	"cw/utility.fxh"
	"cw/curve.fxh"
	"cw/shadow.fxh"
	"cw/camera.fxh"
	"cw/heightmap.fxh"
	"cw/alpha_to_coverage.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_water.fxh"
	"jomini/jomini_mapobject.fxh"
	"jomini/jomini_province_overlays.fxh"
	"dynamic_masks.fxh"
	"pdxmesh_functions.fxh"
	"sharedconstants.fxh"
	"fog_of_war.fxh"
	"distance_fog.fxh"
	"coloroverlay.fxh"
	"ssao_struct.fxh"
	"constants_ig_colors.fxh"
}

VertexStruct VS_OUTPUT
{
	float4 Position			: PDX_POSITION;
	float3 Normal			: TEXCOORD0;
	float3 Tangent			: TEXCOORD1;
	float3 Bitangent		: TEXCOORD2;
	float2 UV0				: TEXCOORD3;
	float2 UV1				: TEXCOORD4;
	float3 WorldSpacePos	: TEXCOORD5;
	uint InstanceIndex 	: TEXCOORD6;
};

VertexShader =
{
	Code
	[[
		VS_OUTPUT ConvertOutput( VS_OUTPUT_PDXMESH In )
		{
			VS_OUTPUT Out;

			Out.Position = In.Position;
			Out.Normal = In.Normal;
			Out.Tangent = In.Tangent;
			Out.Bitangent = In.Bitangent;
			Out.UV0 = In.UV0;
			Out.UV1 = In.UV1;
			Out.WorldSpacePos = In.WorldSpacePos;
			return Out;
		}
	]]

	MainCode VS_navalorder
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				float4x4 WorldMatrix = PdxMeshGetWorldMatrix( Input.InstanceIndices.y );

				#ifdef WINDTRANSFORM
					#if defined( TREE_BUSH )
						Input.Position = WindTransformBush( Input.Position, WorldMatrix );
					#elif defined( TREE_MEDIUM )
						Input.Position = WindTransformMedium( Input.Position, WorldMatrix );
					#elif defined( TREE_TALL )
						Input.Position = WindTransformTall( Input.Position, WorldMatrix );
					#else
						Input.Position = WindTransform( Input.Position, WorldMatrix );
					#endif
				#endif

				#ifdef SNAP_TO_WATER
					Input.Position.y = SnapToWaterLevel( Input.Position.y, WorldMatrix );
				#endif

				VS_OUTPUT Out = ConvertOutput( PdxMeshVertexShaderStandard( Input ) );
				Out.InstanceIndex = Input.InstanceIndices.y;

				#ifdef PDX_MESH_SNAP_VERTICES_TO_TERRAIN
					Out.Normal = SimpleRotateNormalToTerrain( Out.Normal, Out.WorldSpacePos.xz );
				#endif

				return Out;
			}
		]]
	}

	MainCode VS_navalorder_shadow
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT_PDXMESHSHADOWSTANDARD"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PDXMESHSHADOWSTANDARD Out;

				#ifdef SNAP_TO_WATER
					float4x4 WorldMatrix = PdxMeshGetWorldMatrix( Input.InstanceIndices.y );
					Input.Position.y = SnapToWaterLevel( Input.Position.y, WorldMatrix );
				#endif

				Out = PdxMeshVertexShaderShadowStandard( Input );
				return Out;
			}
		]]
	}

	MainCode VS_navalorder_mapobject
	{
		Input = "VS_INPUT_PDXMESH_MAPOBJECT"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				float4x4 WorldMatrix = UnpackAndGetMapObjectWorldMatrix( Input.InstanceIndex24_Opacity8 );

				#ifdef WINDTRANSFORM
					#if defined( TREE_BUSH )
						Input.Position = WindTransformBush( Input.Position, WorldMatrix );
					#elif defined( TREE_MEDIUM )
						Input.Position = WindTransformMedium( Input.Position, WorldMatrix );
					#elif defined( TREE_TALL )
						Input.Position = WindTransformTall( Input.Position, WorldMatrix );
					#else
						Input.Position = WindTransform( Input.Position, WorldMatrix );
					#endif
				#endif

				#ifdef SNAP_TO_WATER
					Input.Position.y = SnapToWaterLevel( Input.Position.y, WorldMatrix );
				#endif

				VS_OUTPUT Out = ConvertOutput( PdxMeshVertexShader( PdxMeshConvertInput( Input ), 0/*Not supported*/, UnpackAndGetMapObjectWorldMatrix( Input.InstanceIndex24_Opacity8 ) ) );
				Out.InstanceIndex = Input.InstanceIndex24_Opacity8;

				#ifdef PDX_MESH_SNAP_VERTICES_TO_TERRAIN
					Out.Normal = SimpleRotateNormalToTerrain( Out.Normal, Out.WorldSpacePos.xz );
				#endif

				return Out;
			}
		]]
	}
	MainCode VS_navalorder_mapobject_shadow
	{
		Input = "VS_INPUT_PDXMESH_MAPOBJECT"
		Output = "VS_OUTPUT_MAPOBJECT_SHADOW"
		Code
		[[
			PDX_MAIN
			{
				uint InstanceIndex;
				float Opacity;
				UnpackMapObjectInstanceData( Input.InstanceIndex24_Opacity8, InstanceIndex, Opacity );
				float4x4 WorldMatrix = GetWorldMatrixMapObject( InstanceIndex );

				#ifdef SNAP_TO_WATER
					Input.Position.y = SnapToWaterLevel( Input.Position.y, WorldMatrix );
				#endif

				VS_OUTPUT_MAPOBJECT_SHADOW Out = ConvertOutputMapObjectShadow( PdxMeshVertexShaderShadow( PdxMeshConvertInput( Input ), 0/*Not supported*/, WorldMatrix ) );
				Out.InstanceIndex24_Opacity8 = Input.InstanceIndex24_Opacity8;
				return Out;
			}
		]]
	}
}

PixelShader =
{
	TextureSampler DiffuseMap
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler PropertiesMap
	{
		Ref = PdxTexture1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler NormalMap
	{
		Ref = PdxTexture2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}

	TextureSampler OrderTexture
	{
		Ref = PdxMeshCustomTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}

	Code
	[[
		float ApplyOpacity( float BaseAlpha, float2 NoiseCoordinate, in uint InstanceIndex )
		{
		#ifdef JOMINI_MAP_OBJECT
			float Opacity = UnpackAndGetMapObjectOpacity( InstanceIndex );
		#else
			float Opacity = PdxMeshGetOpacity( InstanceIndex );
		#endif
			return PdxMeshApplyOpacity( BaseAlpha, NoiseCoordinate, Opacity );
		}

		float3 GetCaustics( float2 Uv )
		{
			// Animated Caustics
			float3x3 BaseMatrix = Create3x3( -2.0, -1.0, 2.0, 3.0, -2.0, 1.0, 1.0, 2.0, 2.0 );
			float2 CausticsUv = Uv * _NavalEmblemConstants._CausticsUv;
			float Speed = 0.05;
			float3 a = mul( float3(CausticsUv.x, CausticsUv.y, GlobalTime * Speed ), BaseMatrix );
			float3 b = mul( a, BaseMatrix ) * 0.4;
			float3 c = mul( b, BaseMatrix ) * 0.3;
			float CausticsNoise = float( pow( min( min( length( 0.5 - frac( a ) ), length( 0.5 - frac( b ) ) ), length( 0.5 - frac( c ) ) ), _NavalEmblemConstants._CausticsArea ) * _NavalEmblemConstants._CausticsStrength );

			float3 CausticsColor = _NavalEmblemConstants._CausticsColor;
			float3 EmblemColor = _NavalEmblemConstants._EmblemColor;
			float3 Caustics = vec3 ( CausticsNoise ) * CausticsColor;

			return Caustics;
		}
	]]

	#// Shader for individual naval order icons which uses the same texture as the UI icon
	MainCode PS_navalorder
	{
		Input = "VS_OUTPUT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			#define DIFFUSE_UV_SET Input.UV0
			#define NORMAL_UV_SET Input.UV0
			#define PROPERTIES_UV_SET Input.UV0

			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float2 MapCoords = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				float2 ProvinceCoords = Input.WorldSpacePos.xz / _ProvinceMapSize;
				float LocalHeight = Input.WorldSpacePos.y - GetHeight( Input.WorldSpacePos.xz );

				float Angle = radians( GetUserDataFloat( Input.InstanceIndex ) );
				float2 Offset = float2( -cos( Angle), sin( Angle ) ) * lerp( _NavalEmblemConstants._EmblemSize, _NavalEmblemConstants._EmblemSizeFlatmap, _FlatmapLerp ) * _NavalEmblemConstants._OrderOffsetDistance;

				float2 Uv = DIFFUSE_UV_SET + Offset;
				float2 texDdx = ddx( DIFFUSE_UV_SET );
				float2 texDdy = ddy( DIFFUSE_UV_SET );
				float2 EmblemUv = lerp( ( Uv - 0.5 ) / max( _NavalEmblemConstants._EmblemSize * _NavalEmblemConstants._OrderCircleSize, 0.01 ) + 0.5, ( Uv - 0.5 ) / max( _NavalEmblemConstants._EmblemSizeFlatmap * _NavalEmblemConstants._OrderCircleSize, 0.01 ) + 0.5, _FlatmapLerp );
				float4 Diffuse = PdxTex2DGrad( DiffuseMap, EmblemUv, texDdx, texDdy );

				float2 OrderUv = lerp( ( Uv - 0.5 ) / max( _NavalEmblemConstants._EmblemSize * _NavalEmblemConstants._OrderIconSize, 0.01 ) + 0.5, ( Uv - 0.5 ) / max( _NavalEmblemConstants._EmblemSizeFlatmap * _NavalEmblemConstants._OrderIconSize, 0.01 ) + 0.5, _FlatmapLerp );
				float4 OrderSample = PdxTex2DGrad( OrderTexture, OrderUv, texDdx, texDdy );
				float3 OrderColor = ToLinear( OrderSample.rgb );
				float OrderAlpha = OrderSample.a;

				float3 Color = Diffuse.rgb;
				float Alpha = saturate( Diffuse.a + OrderAlpha );
				Alpha = lerp( Alpha * _NavalEmblemConstants._EmblemOpacity, Alpha * _NavalEmblemConstants._EmblemOpacityFlatmap, _FlatmapLerp );

				float AlphaClip = Diffuse.a + OrderAlpha;
				AlphaClip = RescaleAlphaByMipLevel( AlphaClip, DIFFUSE_UV_SET, DiffuseMap );
				AlphaClip = SharpenAlpha( AlphaClip, 0.5f );
				clip( AlphaClip - 0.001f );

				// Animated Caustics
				float3 Caustics = GetCaustics( EmblemUv );

				float3 EmblemColor = _NavalEmblemConstants._EmblemColor;
				float Gradient = RemapClamped ( EmblemUv.y + 0.1, -0.0, 1.0, 0.3, 1.0 );

				// Composition
				Color =	Color * EmblemColor + Caustics;
				Color = lerp( Color, OrderColor, OrderAlpha );
				Color *= Gradient;

				// Color overlay, pre light
				#ifndef UNDERWATER
					#ifndef NO_COLOROVERLAY
						float3 ColorOverlay;
						float PreLightingBlend;
						float PostLightingBlend;
						GameProvinceOverlayAndBlend( ProvinceCoords, Input.WorldSpacePos, ColorOverlay, PreLightingBlend, PostLightingBlend );
						Color = ApplyColorOverlay( Color, ColorOverlay, PreLightingBlend );
					#endif
				#endif

				// Effects, post light
				#ifndef UNDERWATER
					#ifndef NO_COLOROVERLAY
						Color = ApplyColorOverlay( Color, ColorOverlay, PostLightingBlend );
					#endif
					#ifndef NO_FOG
						if( _FlatmapLerp < 1.0 )
						{
							float3 Unfogged = Color;
							Color = GameApplyDistanceFog( Color, Input.WorldSpacePos );
							Color = lerp( Color, Unfogged, _FlatmapLerp );
						}
					#endif
				#endif

				// Province Highlight
				Color = ApplyHighlight( Color, ProvinceCoords );

				// Close fade
				Alpha = FadeCloseAlpha( Alpha );
				clip( Alpha - 0.01 );

				// Flatmap
				#ifdef FLATMAP
				 	float LandMask = PdxTex2DLod0( LandMaskMap, float2( MapCoords.x, 1.0 - MapCoords.y ) ).r;
					Alpha *= ( 1.0 - ( LandMask * ( 1.0 - _FlatmapOverlayLandOpacity ) ) );
				#endif

				// Output
				Out.Color = float4( Color, Alpha );
				float3 SSAOColor_ = _SSAOColorMesh.rgb + GameCalculateDistanceFogFactor( Input.WorldSpacePos );
				#ifndef UNDERWATER
					#ifndef NO_COLOROVERLAY
						SSAOColor_ = SSAOColor_ + PostLightingBlend;
					#endif
				#endif
				Out.SSAOColor = float4( saturate ( SSAOColor_ ), Alpha );

				return Out;
			}
		]]
	}

	#// Shader for base of the naval order indicator
	MainCode PS_navalorder_base
	{
		Input = "VS_OUTPUT"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			#define DIFFUSE_UV_SET Input.UV0
			#define NORMAL_UV_SET Input.UV0
			#define PROPERTIES_UV_SET Input.UV0

			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float2 MapCoords = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				float2 ProvinceCoords = Input.WorldSpacePos.xz / _ProvinceMapSize;
				float LocalHeight = Input.WorldSpacePos.y - GetHeight( Input.WorldSpacePos.xz );

				float2 texDdx = ddx( DIFFUSE_UV_SET );
				float2 texDdy = ddy( DIFFUSE_UV_SET );
				float2 EmblemUv = lerp( ( DIFFUSE_UV_SET - 0.5 ) / max( _NavalEmblemConstants._EmblemSize, 0.01 ) + 0.5, ( DIFFUSE_UV_SET - 0.5 ) / max( _NavalEmblemConstants._EmblemSizeFlatmap, 0.01 ) + 0.5, _FlatmapLerp );
				float4 Diffuse = PdxTex2DGrad( DiffuseMap, EmblemUv, texDdx, texDdy );

				float3 Color = Diffuse.rgb;
				float Alpha = saturate( Diffuse.a );
				Alpha = lerp( Alpha * _NavalEmblemConstants._EmblemOpacity, Alpha * _NavalEmblemConstants._EmblemOpacityFlatmap, _FlatmapLerp );

				float AlphaClip = Diffuse.a;
				AlphaClip = RescaleAlphaByMipLevel( AlphaClip, DIFFUSE_UV_SET, DiffuseMap );
				AlphaClip = SharpenAlpha( AlphaClip, 0.5f );
				clip( AlphaClip - 0.001f );

				// Animated Caustics
				float3 Caustics = GetCaustics( EmblemUv );

				float3 EmblemColor = _NavalEmblemConstants._EmblemColor;
				float Gradient = RemapClamped ( EmblemUv.y + 0.1, -0.0, 1.0, 0.3, 1.0 );

				// Composition
				Color =	Color * EmblemColor + Caustics;
				Color *= Gradient;

				// Color overlay, pre light
				#ifndef UNDERWATER
					#ifndef NO_COLOROVERLAY
						float3 ColorOverlay;
						float PreLightingBlend;
						float PostLightingBlend;
						GameProvinceOverlayAndBlend( ProvinceCoords, Input.WorldSpacePos, ColorOverlay, PreLightingBlend, PostLightingBlend );
						Color = ApplyColorOverlay( Color, ColorOverlay, PreLightingBlend );
					#endif
				#endif

				// Effects, post light
				#ifndef UNDERWATER
					#ifndef NO_COLOROVERLAY
						Color = ApplyColorOverlay( Color, ColorOverlay, PostLightingBlend );
					#endif
					#ifndef NO_FOG
						if( _FlatmapLerp < 1.0 )
						{
							float3 Unfogged = Color;
							Color = GameApplyDistanceFog( Color, Input.WorldSpacePos );
							Color = lerp( Color, Unfogged, _FlatmapLerp );
						}
					#endif
				#endif

				// Province Highlight
				Color = ApplyHighlight( Color, ProvinceCoords );

				// Close fade
				Alpha = FadeCloseAlpha( Alpha );
				clip( Alpha - 0.01 );

				// Flatmap
				#ifdef FLATMAP
				 	float LandMask = PdxTex2DLod0( LandMaskMap, float2( MapCoords.x, 1.0 - MapCoords.y ) ).r;
					Alpha *= ( 1.0 - ( LandMask * ( 1.0 - _FlatmapOverlayLandOpacity ) ) );
				#endif

				// Output
				Out.Color = float4( Color, Alpha );
				float3 SSAOColor_ = _SSAOColorMesh.rgb + GameCalculateDistanceFogFactor( Input.WorldSpacePos );
				#ifndef UNDERWATER
					#ifndef NO_COLOROVERLAY
						SSAOColor_ = SSAOColor_ + PostLightingBlend;
					#endif
				#endif
				Out.SSAOColor = float4( saturate ( SSAOColor_ ), Alpha );

				return Out;
			}
		]]
	}
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}
DepthStencilState DepthStencilStateAlphaBlend
{
	DepthEnable = yes
	DepthWriteEnable = no
}
RasterizerState RasterizerState
{
	DepthBias = 0
	SlopeScaleDepthBias = 0
}

# Standard
Effect NavalOrderShader
{
	VertexShader = "VS_navalorder"
	PixelShader = "PS_navalorder"
}
Effect NavalOrderBaseShader
{
	VertexShader = "VS_navalorder"
	PixelShader = "PS_navalorder_base"
}