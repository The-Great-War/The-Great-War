Includes = {
	"cw/terrain.fxh"
	"cw/camera.fxh"
	"cw/shadow.fxh"
	"jomini/jomini_flat_border.fxh"
	"jomini/jomini_lighting.fxh"
	"sharedconstants.fxh"
	"distance_fog.fxh"
	"fog_of_war.fxh"
	"ssao_struct.fxh"
	"pdxverticalborder.fxh"
	"dynamic_masks.fxh"
}

Code
[[
	// BORDER CONSTANTS //
	#define BORDER_ALTERNATE_HIGHT_HIGH 2500.0
	#define BORDER_ALTERNATE_HIGHT_LOW 400.0
	#define BORDER_ALTERNATE_WIDTH_HIGH 5.0
	#define BORDER_ALTERNATE_WIDTH_LOW 1.0
]]

VertexStruct VS_OUTPUT_PDX_BORDER
{
	float4 Position			: PDX_POSITION;
	float3 WorldSpacePos	: TEXCOORD0;
	float2 UV				: TEXCOORD1;
};


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

VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT_PDX_BORDER"
		Output = "VS_OUTPUT_PDX_BORDER"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PDX_BORDER Out;

				float3 Position = float3( Input.Position.x, GetHeight( Input.Center ), Input.Position.y );

				#ifdef COUNTRY_COLOR
					if ( _AlternateCountryBorders == true )
					{
						float2 ExtrudeDir = Input.Center - Input.Position;
						float FadeStart = BORDER_ALTERNATE_HIGHT_LOW - BORDER_ALTERNATE_HIGHT_HIGH;
						float DistanceBlend = FadeStart - CameraPosition.y + BORDER_ALTERNATE_HIGHT_HIGH;
						DistanceBlend = RemapClamped( DistanceBlend, 0.0, FadeStart, BORDER_ALTERNATE_WIDTH_LOW, BORDER_ALTERNATE_WIDTH_HIGH );
						Position = Position - float3( ExtrudeDir.x, 0.0, ExtrudeDir.y ) * DistanceBlend;
					}
				#endif


				Position.y = lerp( Position.y, _FlatmapHeight, _FlatmapLerp );
				Position.y += _HeightOffset;

				Out.WorldSpacePos = Position;
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Position, 1.0 ) );
				Out.UV = Input.UV;

				return Out;
			}
		]]
	}
}

PixelShader =
{
	TextureSampler BorderTexture
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler BorderTexture0
	{
		Ref = JominiVerticalBordersMask0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler ShadowMap
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

	TextureSampler CountryColors
	{
		Ref = CountryColors
		MagFilter = "Point"
		MinFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}

	Code
	[[
		// Flatmap
		#define ANIMATION_SPEED float2( 3.0, 1.0f )
		#define UV_TILING 8

		#define NOISE_MASK_POSITION 1.3f
		#define NOISE_MASK_CONTRAST 2.3f

		#define FLAME_COLOR_1 float3( 1.0f, 0.02f, 0.0f )
		#define FLAME_COLOR_2 float3( 1.0f, 1.0f, 0.0f )
		#define FLAME_COLOR_INTENSITY 3.0f

		#define EDGE_FADE_DISTANCE 0.8
		#define EDGE_FADE_SHARPNESS 5.0

		// War flame settings
		#define FLAME_FADE_DISTANCE 0.64
		#define FLAME_FADE_SHARPNESS 10.0

		#define FLAME_CENTER_INTENSITY 1.0
		#define FLAME_CENTER_DISTANCE 0.54
		#define FLAME_CENTER_SHARPNESS 20.0
		#define FLAME_CENTER_HEIGHTFACTOR_POSITION 0.4
		#define FLAME_CENTER_HEIGHTFACTOR_CONTRAST 0.4

		#define FLAME_MASK_INTENSITY 1.5
		#define FLAME_DEVASTATION_INTENSITY FLAME_MASK_INTENSITY * 1.0

		#define FLAME_HEIGHTFACTOR_POSITION 0.9
		#define FLAME_HEIGHTFACTOR_CONTRAST 1.5

		#define FLAME_SATURATION 1.04
		#define FLAME_EMISSIVE 1.5


		// Escalation smoke settings
		#define ESCALATION_FLAT_COLOR_1 float3( 1.0f, 0.2f, 0.0f )
		#define ESCALATION_FLAT_COLOR_2 float3( 1.0f, 1.0f, 0.0f )
		#define ESCALATION_FLAT_COLOR_INTENSITY 1.5f

		#define ESCALATION_FLAT_EDGE_FADE_DISTANCE 0.80
		#define ESCALATION_FLAT_EDGE_FADE_SHARPNESS 5.0

		#define ESCALATION_FLAT_PULSE_SPEED 1.5

		#define SMOKE_TINT float3( 0.45, 0.45, 0.55 )
		#define SMOKE_FADE_DISTANCE 0.614
		#define SMOKE_FADE_SHARPNESS 10.0

		#define SMOKE_CENTER_INTENSITY 2.0
		#define SMOKE_CENTER_DISTANCE 0.54
		#define SMOKE_CENTER_SHARPNESS 20.0
		#define SMOKE_CENTER_HEIGHTFACTOR_POSITION 0.25
		#define SMOKE_CENTER_HEIGHTFACTOR_CONTRAST 3.0

		#define SMOKE_HEIGHTFACTOR_POSITION 0.9
		#define SMOKE_HEIGHTFACTOR_CONTRAST 2.5


		void ApplyWarFlatmapDiffuse( inout float3 Diffuse, inout float Alpha, float2 WorldSpacePosXZ, float2 UV )
		{
			float2 WorldUV = WorldSpacePosXZ;
			float2 AnimUVs = float2( WorldUV.x, -WorldUV.y ) - GlobalTime * ANIMATION_SPEED;
			AnimUVs = AnimUVs * UV_TILING * 0.001f;

			// Noise
			float NoiseLayer = PdxTex2D( BorderTexture, AnimUVs ).a;
			NoiseLayer = saturate( LevelsScan( NoiseLayer, NOISE_MASK_POSITION, NOISE_MASK_CONTRAST ) );

			// Color
			float4 BottomLayer = float4( FLAME_COLOR_1, 1.0f );
			float4 Color1Layer = float4( FLAME_COLOR_2, NoiseLayer );
			BottomLayer.rgb *= FLAME_COLOR_INTENSITY;
			Color1Layer.rgb *= FLAME_COLOR_INTENSITY;
			float3 FlatmapDiffuse =  AlphaBlendAOverB( Color1Layer, BottomLayer );

			// Alpha
			float FadeRight = UV.y;
			FadeRight = saturate( ( EDGE_FADE_DISTANCE - FadeRight) * EDGE_FADE_SHARPNESS );
			float FadeLeft = 1.0f - UV.y;
			FadeLeft = saturate( ( EDGE_FADE_DISTANCE - FadeLeft ) * EDGE_FADE_SHARPNESS );
			float FlatmapAlpha = FadeRight * FadeLeft;

			Diffuse = lerp( Diffuse, FlatmapDiffuse, _FlatmapLerp );
			Alpha = lerp( Alpha, FlatmapAlpha, _FlatmapLerp );
		}

		void ApplyEscalationPlayFlatmapDiffuse( inout float3 Diffuse, inout float Alpha, float2 WorldSpacePosXZ, float2 UV )
		{
			float2 WorldUV = WorldSpacePosXZ;
			float2 AnimUVs = float2( WorldUV.x, -WorldUV.y ) - GlobalTime * ANIMATION_SPEED;
			AnimUVs = AnimUVs * UV_TILING * 0.001f;

			// Noise
			float NoiseLayer = PdxTex2D( BorderTexture, AnimUVs ).a;
			NoiseLayer = saturate( LevelsScan( NoiseLayer, NOISE_MASK_POSITION, NOISE_MASK_CONTRAST ) );

			// Color
			float4 BottomLayer = float4( ESCALATION_FLAT_COLOR_1, 1.0f );
			float4 Color1Layer = float4( ESCALATION_FLAT_COLOR_2, NoiseLayer );
			BottomLayer.rgb *= ESCALATION_FLAT_COLOR_INTENSITY;
			Color1Layer.rgb *= ESCALATION_FLAT_COLOR_INTENSITY;
			float3 FlatmapDiffuse =  AlphaBlendAOverB( Color1Layer, BottomLayer );

			// Alpha
			float FadeRight = UV.y;
			FadeRight = saturate( ( ESCALATION_FLAT_EDGE_FADE_DISTANCE - FadeRight) * ESCALATION_FLAT_EDGE_FADE_SHARPNESS );
			float FadeLeft = 1.0f - UV.y;
			FadeLeft = saturate( ( ESCALATION_FLAT_EDGE_FADE_DISTANCE - FadeLeft ) * ESCALATION_FLAT_EDGE_FADE_SHARPNESS );
			float FlatmapAlpha = FadeRight * FadeLeft;

			Diffuse = lerp( Diffuse, FlatmapDiffuse, _FlatmapLerp );
			Alpha = lerp( Alpha, FlatmapAlpha, _FlatmapLerp );
		}

		float GetFade( float2 UV, float Distance, float Sharpness )
		{
			float FadeRight = UV.y;
			FadeRight = saturate( ( Distance - FadeRight) * Sharpness );
			float FadeLeft = 1.0f - UV.y;
			FadeLeft = saturate( ( Distance - FadeLeft ) * Sharpness );
			float Fade = FadeLeft * FadeRight;

			return Fade;
		}

		float3 ApplyDevastationMaterialVFXBorder( inout float4 Diffuse, float2 UV, float FlameMask )
		{
			// Effect Properties
			float FireUVDistortionStrength = 0.5f;
			float2 PanSpeedA = float2( 0.005, 0.001 );
			float2 PanSpeedB = float2( 0.010, 0.005 );

			// UV & UV Panning Properties
			float2 UVPan02 = float2( -frac( GlobalTime * PanSpeedA.x ), frac( GlobalTime * PanSpeedA.y ) );
			float2 UVPan01 = float2( frac( GlobalTime * PanSpeedB.x ),  frac( GlobalTime * PanSpeedB.y ) );
			float2 UV02 = ( UV + 0.5 ) * 0.1;
			float2 UV01 = UV * 0.2;

			// Pan and Sample noise for UV distortion
			UV02 += UVPan02;
			float DevastationAlpha02 = PdxTex2D( DevastationPollution, float3( UV02, DevastationTexIndex + DevastationTexIndexOffset ) ).a;

			// Apply the UV Distortion
			UV01 += UVPan01;
			UV01 += DevastationAlpha02 * FireUVDistortionStrength;
			float DevastationAlpha01 = PdxTex2D( DevastationPollution, float3( UV01, DevastationTexIndex + DevastationTexIndexOffset ) ).a;

			// Adjust Mask Value ranges to clamp the effect
			DevastationAlpha01 = max( smoothstep( 0.2, 0.6, DevastationAlpha01 ), 0.5 );

			// Calculate the effect masks
			FlameMask = saturate( FlameMask * DevastationAlpha01 );

			float LutCoord = RemapClamped( FlameMask, 0.0, 1.0, -1.0, 0.84 );
			float3 FlameColor = PdxTex2D( VerticalBorderLUT , saturate( float2( LutCoord, 0.0 ) ) ).rgb;
			FlameColor *= FlameMask;

			float3 HSV_ = RGBtoHSV( FlameColor );
			HSV_.y *= FLAME_SATURATION;
			FlameColor = HSVtoRGB( HSV_ );

			FlameColor *= FLAME_EMISSIVE;

			return FlameColor;
		}
	]]

	MainCode BorderPs
	{
		Input = "VS_OUTPUT_PDX_BORDER"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float2 texDdx = ddx( Input.UV );
				float2 texDdy = ddy( Input.UV );

				float4 Diffuse = PdxTex2DGrad( BorderTexture, Input.UV, texDdx, texDdy );

				#ifdef COUNTRY_COLOR
					float4 CountryColor = PdxTex2DLoad0( CountryColors, int2( _UserId, 0 ) );
					Diffuse.rgb *= CountryColor.rgb;

					if ( _AlternateCountryBorders == true )
					{
						float OutlineOuter = saturate( ( BORDER_ALTERNATE_OUTLINE_OUTER_MIN - ( Input.UV.y - 1.0 ) ) * BORDER_ALTERNATE_OUTLINE_OUTER_MAX );
						float OutlineInner = saturate( ( BORDER_ALTERNATE_OUTLINE_INNER_MIN - ( 0.5 - Input.UV.y ) ) * BORDER_ALTERNATE_OUTLINE_INNER_MAX );
						Diffuse.rgb = lerp( Diffuse.rgb, vec3( 0.0 ), OutlineOuter );
						Diffuse.rgb = lerp( Diffuse.rgb, vec3( 0.0 ), OutlineInner );
						Diffuse.a = lerp( Diffuse.a, Diffuse.a * 0.8f, _FlatmapLerp );
					}
					else
					{
						Diffuse.rgb *= 1.0f - _FlatmapLerp;
						Diffuse.a = lerp( Diffuse.a, 0.5f, _FlatmapLerp );
					}

				#endif

				#ifdef IMPASSABLE_BORDER
					Diffuse.rgb *= _ImpassableTerrainColor.rgb;
				#endif

				if( _FlatmapLerp < 1.0f )
				{
					float3 Unfogged = Diffuse.rgb;
					Diffuse.rgb = ApplyFogOfWar( Diffuse.rgb, Input.WorldSpacePos );
					Diffuse.rgb = GameApplyDistanceFog( Diffuse.rgb, Input.WorldSpacePos );
					Diffuse.rgb = lerp( Diffuse.rgb, Unfogged, _FlatmapLerp );
				}

				// Close fadeout
				Diffuse.a = FadeCloseAlpha( Diffuse.a );
				Diffuse.a *= _Alpha;

				// Output
				Out.Color = Diffuse;

				// Process to mask out SSAO where borders become opaque, using SSAO color
				Out.SSAOColor = float4( 1.0f, 1.0f, 1.0f, Diffuse.a );

				return Out;
			}
		]]
	}

	MainCode FlatWarBorderPs
	{
		Input = "VS_OUTPUT_PDX_BORDER"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float Alpha = 1.0f;

				// UVs
				float2 MapCoordinates = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				float2 DetailUV = CalcDetailUV( Input.WorldSpacePos.xz );

				// Get terrain material
				float4 Diffuse;
				float3 Normal;
				float4 Properties;
				CalculateDetails( Input.WorldSpacePos.xz, Diffuse, Normal, Properties );

				float3 ColorMap = PdxTex2D( ColorTexture, float2( MapCoordinates.x, 1.0 - MapCoordinates.y ) ).rgb;
				Diffuse.rgb = SoftLight( Diffuse.rgb, ColorMap, ( 1.0 - Diffuse.r ) );

				float3 TerrainNormal = CalculateNormal( Input.WorldSpacePos.xz );
				Normal = ReorientNormal( TerrainNormal, Normal );

				// Get Devastation materials
				float4 DevDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, DevastationTexIndex + DevastationTexIndexOffset ) );
				float4 DevProperties = PdxTex2D( MaterialTextures, float3( DetailUV, DevastationTexIndex + DevastationTexIndexOffset ) );
				float4 DevNormalRRxG = PdxTex2D( NormalTextures, float3( DetailUV, DevastationTexIndex + DevastationTexIndexOffset ) );
				float3 DevNormal = UnpackRRxGNormal( DevNormalRRxG ).xyz;
				DevNormal = ReorientNormal( Normal, DevNormal );

				// Devastation value
				float Devastation = saturate( GetDevastation( MapCoordinates ) * 5.0 );
				Devastation *= GetDevastationExclusionMask( MapCoordinates );

				// Devastation material
				Diffuse.rgb = lerp( Diffuse.rgb, DevDiffuse.rgb, Devastation );
				Properties = lerp( Properties, DevProperties, Devastation );
				Normal = lerp( Normal, DevNormal, Devastation );

				// Ground Flame mask
				Diffuse.a = lerp( 1.0 - Diffuse.a, Overlay( 1.0 - Diffuse.a, DevDiffuse.a ), Devastation );

				float CenterFlame = saturate( GetFade( Input.UV, FLAME_CENTER_DISTANCE, FLAME_CENTER_SHARPNESS ) * FLAME_CENTER_INTENSITY );
				float FlameContrast = lerp( FLAME_HEIGHTFACTOR_CONTRAST, FLAME_CENTER_HEIGHTFACTOR_CONTRAST, CenterFlame );
				float FlamePosition = lerp( FLAME_HEIGHTFACTOR_POSITION, FLAME_CENTER_HEIGHTFACTOR_POSITION, CenterFlame );

				// Mask Intensity
				float FlameMask = LevelsScan( Diffuse.a, FlamePosition, FlameContrast );
				float FlameFade = GetFade( Input.UV, FLAME_FADE_DISTANCE, FLAME_FADE_SHARPNESS );
				FlameMask *= lerp( FLAME_MASK_INTENSITY, FLAME_DEVASTATION_INTENSITY, Devastation ) * FlameFade;

				// Light calculation (terrain)
				SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal, Properties.a, Properties.g, Properties.b );
				SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, ShadowMap );
				Diffuse.rgb = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );

				// Apply Flame emissive
				Diffuse.rgb += ApplyDevastationMaterialVFXBorder( Diffuse, DetailUV, FlameMask );

				// Effects
				if( _FlatmapLerp < 1.0f )
				{
					Diffuse.rgb = ApplyFogOfWar( Diffuse.rgb, Input.WorldSpacePos, 1.0 - FlameMask );
					Diffuse.rgb = GameApplyDistanceFog( Diffuse.rgb, Input.WorldSpacePos );
				}

				// Fade alpha
				float EdgeFade = lerp( FlameFade, GetFade( Input.UV, EDGE_FADE_DISTANCE, EDGE_FADE_SHARPNESS ), _FlatmapLerp );
				Alpha *= EdgeFade;

				// Flatmap
				ApplyWarFlatmapDiffuse( Diffuse.rgb, Alpha, Input.WorldSpacePos.xz, Input.UV );

				// Output
				Out.Color.rgb = Diffuse.rgb;
				Out.Color.a = Alpha;

				// Process to mask out SSAO where borders become opaque, using SSAO color
				Out.SSAOColor = float4( 1.0f, 1.0f, 1.0f, Alpha );

				DebugReturn( Out.Color.rgb, MaterialProps, LightingProps, EnvironmentMap );
				return Out;
			}
		]]
	}

	MainCode FlatEscalationBorderPs
	{
		Input = "VS_OUTPUT_PDX_BORDER"
		Output = "PS_COLOR_SSAO"
		Code
		[[
			PDX_MAIN
			{
				PS_COLOR_SSAO Out;

				float Alpha = 1.0f;

				// UVs
				float2 MapCoordinates = Input.WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
				float2 DetailUV = CalcDetailUV( Input.WorldSpacePos.xz );

				// Get terrain material
				float4 Diffuse;
				float3 Normal;
				float4 Properties;
				CalculateDetails( Input.WorldSpacePos.xz, Diffuse, Normal, Properties );

				float3 ColorMap = PdxTex2D( ColorTexture, float2( MapCoordinates.x, 1.0 - MapCoordinates.y ) ).rgb;
				Diffuse.rgb = SoftLight( Diffuse.rgb, ColorMap, ( 1.0 - Diffuse.r ) );

				float3 TerrainNormal = CalculateNormal( Input.WorldSpacePos.xz );
				Normal = ReorientNormal( TerrainNormal, Normal );

				// Get Devastation materials
				float4 DevDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, DevastationTexIndex + DevastationTexIndexOffset ) );
				float4 DevProperties = PdxTex2D( MaterialTextures, float3( DetailUV, DevastationTexIndex + DevastationTexIndexOffset ) );
				float4 DevNormalRRxG = PdxTex2D( NormalTextures, float3( DetailUV, DevastationTexIndex + DevastationTexIndexOffset ) );
				float3 DevNormal = UnpackRRxGNormal( DevNormalRRxG ).xyz;
				DevNormal = ReorientNormal( Normal, DevNormal );

				// Devastation value
				float Devastation = saturate( GetDevastation( MapCoordinates ) * 5.0 );
				Devastation *= GetDevastationExclusionMask( MapCoordinates );

				// Devastation material
				Diffuse.rgb = lerp( Diffuse.rgb, DevDiffuse.rgb, Devastation );
				Properties = lerp( Properties, DevProperties, Devastation );
				Normal = lerp( Normal, DevNormal, Devastation );

				// Ground Flame mask
				Diffuse.a = lerp( 1.0 - Diffuse.a, Overlay( 1.0 - Diffuse.a, DevDiffuse.a ), Devastation );

				// UV & UV Panning Properties
				float2 BaseUv = Input.UV * 5.0;

				// Textures
				float2 PanSpeed01 = float2( 0.0, 0.1 );
				float2 PanSpeed02 = float2( 0.0, 0.1 );
				float2 UvPanning01 = GlobalTime * PanSpeed01;
				float2 UvPanning02 = GlobalTime * PanSpeed02;
				float2 Uv01 = BaseUv + UvPanning01;
				float2 Uv02 = BaseUv + UvPanning02;

				// UV & UV Panning Properties
				float2 NoisePanSpeed01 = float2( 0.1, 0.1 );
				float2 NoisePanSpeed02 = float2( -0.1, 0.1 );
				float2 NoisePanSpeed03 = float2( -0.2, 0.1 );
				float2 NoiseUvPanning01 = GlobalTime * NoisePanSpeed01;
				float2 NoiseUvPanning02 = GlobalTime * NoisePanSpeed02;
				float2 NoiseUvPanning03 = GlobalTime * NoisePanSpeed03;
				float2 NoiseUv01 = BaseUv + NoiseUvPanning01;
				float2 NoiseUv02 = BaseUv + NoiseUvPanning02;
				float2 NoiseUv03 = BaseUv + NoiseUvPanning03;

				// Noise
				float Noise01 = vec3( ToLinear( PdxTex2D( DevastationPollution, NoiseUv01 * 0.5 ).a ) );
				float Noise02 = vec3( ToLinear( PdxTex2D( BorderTexture0, NoiseUv02 * 0.45 ).a ) );
				float Noise03 = vec3( ToLinear( PdxTex2D( BorderTexture0, NoiseUv03 * 0.25 ).a ) );
				float NoiseSum = Noise01 + Noise02 + Noise03;
				NoiseSum = smoothstep( -1.0, 1.0, NoiseSum );

				// Color
				float Color01 = vec3( PdxTex2D( BorderTexture0, Uv01 * 0.1 + NoiseSum * 0.015 ).r );
				float Color02 = vec3( PdxTex2D( BorderTexture0, Uv02 * 0.25 + NoiseSum * 0.015 ).b );

				float3 Color = SoftLight( Color01, Color02 );
				Color = Overlay( Color, SMOKE_TINT );
				Diffuse.rgb = lerp( Diffuse.rgb, Color, NoiseSum );

				float CenterMask = saturate( GetFade( Input.UV, SMOKE_CENTER_DISTANCE, SMOKE_CENTER_SHARPNESS ) * SMOKE_CENTER_INTENSITY );
				float Contrast = lerp( SMOKE_HEIGHTFACTOR_CONTRAST, SMOKE_CENTER_HEIGHTFACTOR_CONTRAST, CenterMask );
				float Position = lerp( SMOKE_HEIGHTFACTOR_POSITION, SMOKE_CENTER_HEIGHTFACTOR_POSITION, CenterMask );

				// Mask Intensity
				float MaskFade = GetFade( Input.UV, SMOKE_FADE_DISTANCE, SMOKE_FADE_SHARPNESS );
				float GroundMask = LevelsScan( Diffuse.a, Position, Contrast );
				GroundMask *= MaskFade;

				// Fade alpha
				float EdgeFade = lerp( MaskFade, GetFade( Input.UV, EDGE_FADE_DISTANCE, EDGE_FADE_SHARPNESS ), _FlatmapLerp );
				Alpha = Alpha * EdgeFade * GroundMask * NoiseSum;

				// Flatmap
				ApplyEscalationPlayFlatmapDiffuse( Diffuse.rgb, Alpha, Input.WorldSpacePos.xz, Input.UV );

				// Output
				Out.Color.rgb = Diffuse.rgb;
				Out.Color.a = Alpha;

				float Pulse = sin( GlobalTime * ESCALATION_FLAT_PULSE_SPEED ) * 0.5 + 0.5;
				Out.Color.rgb = lerp( Out.Color.rgb, vec3( 0.25 ), Pulse * 0.75  );

				if( _FlatmapLerp < 1.0f )
				{
					Diffuse.rgb = ApplyFogOfWar( Diffuse.rgb, Input.WorldSpacePos, 1.0 - GroundMask );
					Diffuse.rgb = GameApplyDistanceFog( Diffuse.rgb, Input.WorldSpacePos );
				}

				// Process to mask out SSAO where borders become opaque, using SSAO color
				Out.SSAOColor = float4( 1.0f, 1.0f, 1.0f, Alpha );

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
	WriteMask = "RED|GREEN|BLUE"
}

RasterizerState RasterizerState
{
	DepthBias = -300
	SlopeScaleDepthBias = -10
}

DepthStencilState DepthStencilState
{
	DepthEnable = yes
	DepthWriteEnable = no
}

Effect DefaultBorder
{
	VertexShader = "VertexShader"
	PixelShader = "BorderPs"
}
Effect CountryBorder
{
	VertexShader = "VertexShader"
	PixelShader = "BorderPs"
	Defines = { "COUNTRY_COLOR" }
}
Effect ImpassableBorder
{
	VertexShader = "VertexShader"
	PixelShader = "BorderPs"
	Defines = { "IMPASSABLE_BORDER" }
}
Effect FlatWarBorder
{
	VertexShader = "VertexShader"
	PixelShader = "FlatWarBorderPs"
}
Effect FlatEscalationBorder
{
	VertexShader = "VertexShader"
	PixelShader = "FlatEscalationBorderPs"
}