Includes = {
	"cw/heightmap.fxh"
	"cw/utility.fxh"
	"cw/camera.fxh"
	"cw/shadow.fxh"
	"cw/random.fxh"
	"jomini/jomini_fog.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_water.fxh"
	"jomini/jomini_water_default.fxh"
	"jomini/jomini_river.fxh"
	"jomini/jomini_fog_of_war.fxh"
	"dynamic_masks.fxh"
	"constants_game.fxh"
	"fog_of_war.fxh"
}

PixelShader =
{
	Code
	[[
		// Shore
		#define WavesMaskLargeContrast -0.233
		#define WavesMaskLargePosition 0.609
		#define WavesInnerFadeContrast 0.25
		#define WavesInnerFadePosition 0.15
		#define WavesFlowFoamContrast 0.96
		#define WavesFlowFoamPosition 1.23

		#define FoamNoiseContrast 1.6
		#define FoamNoisePosition 1.4

		#define LargeNoiseContrast 0.75
		#define LargeNoisePosition 0.57
		#define LargeNoiseScale 0.01
		#define LargeNoiseSpeed 0.004

		#define ShoreMaskLargeContrast 	0.754
		#define ShoreMaskLargePosition 	0.266
		#define ShoreInnerFadeContrast 	0.102
		#define ShoreInnerFadePosition 	0.108
		#define ShoreFlowFoamContrast 0.39
		#define ShoreFlowFoamPosition 0.55

		#define CausticsMaskLargeContrast 3.246
		#define CausticsMaskLargePosition 2.754
		#define CausticsInnerFadeContrast 0.102
		#define CausticsInnerFadePosition 0.108

		// Ocean
		#define OceanWaveNoiseMin 0.1
		#define OceanWaveNoiseMax 1.0

		#define OceanWaveStrength 0.25
		#define OceanWaveMin 1.85
		#define OceanWaveMax 2.9

		#define OceanFadeMin -0.7
		#define OceanFadeMax 1.1

		#define OceanDistanceEnd		1050.0
		#define OceanWaveDistanceEnd	250.0
		#define OceanDistanceStart 		50.0

		#define OceanGlossModifier	 	0.75
		#define OceanSpecModifier 		15.0
		#define OceanFactorMultiplier	0.75

		#define CloudReflectionDistortion 	20.0
		#define CloudReflectionNoiseUv 		100.0
		#define CloudReflectionNormalDistortionMin 150.0
		#define CloudReflectionNormalDistortionMax 1000.0
		#define CloudReflectionStrength 0.05

		// Pond
		#define PondGlossScale 		0.5
		#define PondSpecular 		0.75

		#define PondNormalUvScale 	3.0
		#define PondNormalFlatten 	0.1
		#define PondWaveSpeed 		0.5

		#define PondDepthScale 		0.45
		#define PondDepthContrast 	1.25

		#define PondFoamScale 			8.0
		#define PondFoamDistortFactor 	0.1
		#define PondFoamSpeed			0.03
		#define PondCausticsStrength 	5.0
	]]

}


PixelShader =
{
	#//Same data that is being used in the river bottom shader
	TextureSampler BottomDiffuse
	{
		Ref = JominiRiver0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}

	TextureSampler BottomNormal
	{
		Ref = JominiRiver1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}

	TextureSampler BottomProperties
	{
		Ref = JominiRiver2
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

	Code
	[[
		float LevelsScanP( float vInValue, float vPosition, float vRange )
		{
			return saturate( Levels( vInValue, vPosition - vRange, vPosition + vRange ) );
		}

		void AdjustOceanSpecular( inout SWaterLightingProperties lightingProperties, float OceanFactor )
		{
			float AdjustedGlossBase = lerp( lightingProperties._Glossiness, lightingProperties._Glossiness * OceanGlossModifier, OceanFactor );
			lightingProperties._Glossiness = AdjustedGlossBase;
			lightingProperties._NonLinearGlossiness = GetNonLinearGlossiness( lightingProperties._Glossiness ) * _WaterGlossScale;

			lightingProperties._SpecularColor *= lerp( 1.0, OceanSpecModifier, OceanFactor );
		}

		float3 CalcFlowGame( PdxTextureSampler2D FlowMapTexture, PdxTextureSampler2D FlowNormalTexture, float2 FlowMapUV, float2 NormalMapUV, out float FoamMask )
		{
			float FlowMapScale = 5.0;
			float2 FlowCoordScale = _WaterFlowMapSize * FlowMapScale;
			float2 FlowCoord = FlowMapUV * FlowCoordScale;

			float2 BlendFactor = abs( 2.0 * frac( FlowCoord ) - 1.0 ) - 0.5;
			BlendFactor = 0.5 - 4.0 * BlendFactor * BlendFactor * BlendFactor;

			float2 NormalCoord = NormalMapUV * _WaterFlowNormalScale;
			float2 DDX = ddx( NormalCoord );
			float2 DDY = ddy( NormalCoord );

			float2 Offset = float2( 0.0, -_WaterFlowTime );

			float4 Sample1;
			SampleFlowTexture( FlowMapTexture, FlowNormalTexture, floor( FlowCoord ) / FlowCoordScale, NormalCoord, Offset, DDX, DDY, Sample1.xyz, Sample1.a );
			float4 Sample2;
			SampleFlowTexture( FlowMapTexture, FlowNormalTexture, floor( FlowCoord + float2( 0.5, 0.0 ) ) / FlowCoordScale, NormalCoord, Offset, DDX, DDY, Sample2.xyz, Sample2.a );
			float4 Sample3;
			SampleFlowTexture( FlowMapTexture, FlowNormalTexture, floor( FlowCoord + float2( 0.0, 0.5 ) ) / FlowCoordScale, NormalCoord, Offset, DDX, DDY, Sample3.xyz, Sample3.a );
			float4 Sample4;
			SampleFlowTexture( FlowMapTexture, FlowNormalTexture, floor( FlowCoord + float2( 0.5, 0.5 ) ) / FlowCoordScale, NormalCoord, Offset, DDX, DDY, Sample4.xyz, Sample4.a );

			float4 Sample12 = lerp( Sample2, Sample1, BlendFactor.x );
			float4 Sample34 = lerp( Sample4, Sample3, BlendFactor.x );

			float4 Sample = lerp( Sample34, Sample12, BlendFactor.y );

			Sample.y *= _WaterFlowNormalFlatten;
			float3 Normal = normalize( Sample.xyz );

			FoamMask = Sample.a;
			return Normal;
		}

		float GameCalcOceanWaves( float2 UV01, float2 WorldSpacePosXZ, float FlowFoamMask, float3 FlowNormal, float OceanFactor )
		{
			// Noise
			float2 LargeNoiseUV = WorldSpacePosXZ * LargeNoiseScale * 8;
			float LargeNoise = PdxTex2D( FoamNoiseTexture, LargeNoiseUV + float2( 1.0f, 1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed * 4.0 ).r;
			float LargeNoise2 = PdxTex2D( FoamNoiseTexture, LargeNoiseUV * 0.5 + float2( -1.0f, 1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed * 4.0 ).r;
			LargeNoise = LargeNoise * LargeNoise2;
			LargeNoise = smoothstep( OceanWaveNoiseMin, OceanWaveNoiseMax, LargeNoise ) * OceanWaveStrength;

			// Foamnoise under waves
			float3 Foam = PdxTex2D( FoamTexture, WorldSpacePosXZ * _WaterFoamScale + FlowNormal.xz * 0.1 ).rgb;

			// Wave Size/Contrast
			FlowFoamMask = LevelsScan( FlowFoamMask, OceanWaveMin, OceanWaveMax );
			float3 FoamRamp = PdxTex2DLod0( FoamRampTexture, float2( FlowFoamMask, 0.5 ) ).rgb;
			float OceanWavesFoam = saturate( dot( Foam, FoamRamp ) );

			// Waves
			float Strength = 400.0f * _WaterFoamStrength * smoothstep( 0.5, 1.0, OceanFactor );
			OceanWavesFoam = Overlay( OceanWavesFoam, FlowFoamMask ) * LargeNoise * Strength;

			return OceanWavesFoam;
		}

		float GameCalcFoamFactorWaves( float2 UV01, float2 WorldSpacePosXZ, float Depth, float FlowFoamMask, float3 FlowNormal )
		{
			float FoamMaskLarge = LevelsScanP( 1.0f - Depth, WavesMaskLargeContrast, WavesMaskLargePosition );

			float FoamMaskInnerRemove = LevelsScanP( Depth, WavesInnerFadeContrast, WavesInnerFadePosition );
			FoamMaskLarge *= FoamMaskInnerRemove;

			float3 Foam = PdxTex2D( FoamTexture, WorldSpacePosXZ * _WaterFoamScale + FlowNormal.xz * _WaterFoamDistortFactor ).rgb;

			FlowFoamMask = LevelsScan( FlowFoamMask, WavesFlowFoamContrast, WavesFlowFoamPosition );
			float3 FoamRamp = PdxTex2DLod0( FoamRampTexture, float2( FoamMaskLarge * FlowFoamMask, 0.5 ) ).rgb;

			// Break apart noise
			float2 NoiseUV = WorldSpacePosXZ * _WaterFoamNoiseScale;
			float FoamNoise1 = PdxTex2D( FoamNoiseTexture, NoiseUV + float2( 1.0f, -1.0f ) * JOMINIWATER_GlobalTime * _WaterFoamNoiseSpeed ).r;
			FoamNoise1 = LevelsScanP( FoamNoise1, FoamNoiseContrast, FoamNoisePosition );

			float2 LargeNoiseUV = WorldSpacePosXZ * LargeNoiseScale;
			float LargeNoise = PdxTex2D( FoamNoiseTexture, LargeNoiseUV + float2( 1.0f, -1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed ).r;
			float LargeNoise2 = PdxTex2D( FoamNoiseTexture, LargeNoiseUV + float2( -1.0f, 1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed ).r;
			LargeNoise = Overlay( LargeNoise2, LargeNoise );
			LargeNoise = LevelsScanP( LargeNoise, LargeNoisePosition, LargeNoiseContrast );

			// Large waves
			float FoamResult = saturate( dot( Foam, FoamRamp ) ) * FoamMaskLarge;
			float Strength = 50.0f * _WaterFoamStrength;
			FoamResult = Overlay( FoamResult, FlowFoamMask ) * Strength * FoamNoise1 * LargeNoise;

			return FoamResult;
		}

		float GameCalcFoamFactorShore( float2 UV01, float2 WorldSpacePosXZ, float Depth, float FlowFoamMask, float3 FlowNormal )
		{
			// Foam calculation
			float FoamMaskLarge = LevelsScanP( 1.0f - Depth, ShoreMaskLargeContrast, ShoreMaskLargePosition );

			float FoamMaskInnerRemove = LevelsScanP( Depth, ShoreInnerFadeContrast, ShoreInnerFadePosition );
			FoamMaskLarge *= FoamMaskInnerRemove;

			float3 Foam = PdxTex2D( FoamTexture, WorldSpacePosXZ * _WaterFoamScale + FlowNormal.xz * _WaterFoamDistortFactor ).rgb;

			FlowFoamMask = LevelsScan( FlowFoamMask, ShoreFlowFoamContrast, ShoreFlowFoamPosition );
			float3 FoamRamp = PdxTex2DLod0( FoamRampTexture, float2( FoamMaskLarge * FlowFoamMask, 0.5 ) ).rgb;

			// Break apart noise
			float2 NoiseUV = WorldSpacePosXZ * _WaterFoamNoiseScale;
			float FoamNoise = PdxTex2D( FoamNoiseTexture, NoiseUV + float2( 1.0f, 1.0f ) * JOMINIWATER_GlobalTime * _WaterFoamNoiseSpeed  ).r;
			FoamNoise = LevelsScanP( FoamNoise, FoamNoiseContrast, FoamNoisePosition );

			float2 LargeNoiseUV = WorldSpacePosXZ * LargeNoiseScale;
			float LargeNoise = PdxTex2D( FoamNoiseTexture, LargeNoiseUV + float2( 1.0f, -1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed ).r;
			float LargeNoise2 = PdxTex2D( FoamNoiseTexture, LargeNoiseUV + float2( -1.0f, 1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed ).r;
			LargeNoise = Overlay( LargeNoise2, LargeNoise );
			LargeNoise = LevelsScanP( LargeNoise, LargeNoisePosition, LargeNoiseContrast );

			// Large waves
			float FoamResult = dot( Foam, FoamRamp ) * FoamMaskLarge;
			float Strength = 50.0f * _WaterFoamStrength;
			FoamResult = Overlay( FoamResult, FlowFoamMask ) * Strength * FoamNoise * LargeNoise;

			return saturate( FoamResult );
		}

		float GameCalcFoamFactorCaustics( float2 UV01, float2 WorldSpacePosXZ, float Depth, float FlowFoamMask, float3 FlowNormal )
		{
			// Foam calculation
			float FoamMaskLarge = LevelsScanP( 1.0f - Depth, CausticsMaskLargeContrast, CausticsMaskLargePosition );

			float FoamMaskInnerRemove = LevelsScanP( Depth, CausticsInnerFadeContrast, CausticsInnerFadePosition );
			FoamMaskLarge *= FoamMaskInnerRemove;

			float3 Foam = PdxTex2D( FoamTexture, WorldSpacePosXZ * _WaterFoamScale + FlowNormal.xz * _WaterFoamDistortFactor ).rgb;

			float3 FoamRamp = PdxTex2DLod0( FoamRampTexture, float2( FoamMaskLarge, 0.5 ) ).rgb;

			// Break apart noise
			float2 NoiseUV = WorldSpacePosXZ * _WaterFoamNoiseScale * 0.5f;
			float FoamNoise = PdxTex2D( FoamNoiseTexture, NoiseUV + float2( 1.0f, 1.0f ) * JOMINIWATER_GlobalTime * _WaterFoamNoiseSpeed  ).r;

			float2 LargeNoiseUV = WorldSpacePosXZ * LargeNoiseScale;
			float LargeNoise = PdxTex2D( FoamNoiseTexture, LargeNoiseUV + float2( 1.0f, -1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed ).r;
			float LargeNoise2 = PdxTex2D( FoamNoiseTexture, LargeNoiseUV + float2( -1.0f, 1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed ).r;
			LargeNoise = Overlay( LargeNoise2, LargeNoise );
			LargeNoise = LevelsScanP( LargeNoise, LargeNoisePosition, LargeNoiseContrast );

			// Large waves
			float FoamResult = dot( Foam, FoamRamp ) * FoamMaskLarge;
			float Strength = 100.0f * _WaterFoamStrength;
			FoamResult = FoamResult * Strength * FoamNoise * LargeNoise;

			return saturate( FoamResult );
		}

		float GameCalcPondFoam( float2 UV01, float2 WorldSpacePosXZ, float Depth, float FlowFoamMask, float3 FlowNormal )
		{
			// Foam calculation
			float FoamMaskLarge = LevelsScanP( 1.0f - Depth, CausticsMaskLargeContrast, CausticsMaskLargePosition );

			float FoamMaskInnerRemove = LevelsScanP( Depth, CausticsInnerFadeContrast, CausticsInnerFadePosition );
			FoamMaskLarge *= FoamMaskInnerRemove;

			float3 Foam = PdxTex2D( FoamTexture, WorldSpacePosXZ * PondFoamScale + FlowNormal.xz * PondFoamDistortFactor ).rgb;

			float3 FoamRamp = PdxTex2DLod0( FoamRampTexture, float2( FoamMaskLarge, 0.5 ) ).rgb;

			// Break apart noise
			float2 NoiseUV = WorldSpacePosXZ;
			float FoamNoise = PdxTex2D( FoamNoiseTexture, NoiseUV + float2( 1.0f, 1.0f ) * JOMINIWATER_GlobalTime * PondFoamSpeed  ).r;

			float2 LargeNoiseUV = WorldSpacePosXZ * LargeNoiseScale;
			float LargeNoise = PdxTex2D( FoamNoiseTexture, LargeNoiseUV + float2( 1.0f, -1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed ).r;
			float LargeNoise2 = PdxTex2D( FoamNoiseTexture, LargeNoiseUV + float2( -1.0f, 1.0f ) * JOMINIWATER_GlobalTime * LargeNoiseSpeed ).r;
			LargeNoise = Overlay( LargeNoise2, LargeNoise );
			LargeNoise = LevelsScanP( LargeNoise, LargeNoisePosition, LargeNoiseContrast );

			// Large waves
			float FoamResult = dot( Foam, FoamRamp ) * FoamMaskLarge;
			float Strength = 100.0f * _WaterFoamStrength * PondCausticsStrength;
			FoamResult = FoamResult * Strength * FoamNoise * LargeNoise;

			return saturate( FoamResult );
		}

		float3 GameCalcRefraction( float3 WorldSpacePos, float3 Normal, float2 ScreenPos, float3 WaterColor, float Depth )
		{
			float3 WaterColorMap = lerp( WaterColor, _WaterColorMapTint, _WaterColorMapTintFactor ) * _NightWaterAdjustment;

			#if defined( JOMINI_REFRACTION_ENABLED )
				float4 RefractionSample = PdxTex2DLod0( RefractionTexture, ScreenPos / _ScreenResolution );
				float3 RefractionWorldSpacePos = DecompressWorldSpace( WorldSpacePos, RefractionSample.a );
				float RefractionDepth = WorldSpacePos.y - RefractionWorldSpacePos.y;
				Depth = min( Depth, RefractionDepth );

				float RefractionShoreMask = 1.0 - saturate( ( _WaterRefractionShoreMaskDepth - Depth ) * _WaterRefractionShoreMaskSharpness );

				float2 RefractionOffset = mul( ViewMatrix, float4( Normal.x, 0, Normal.z, 0 ) ).xy * float2(-1, 1);
				RefractionOffset *= _WaterRefractionScale * RefractionShoreMask * _WaterRefractionFade;

				float4 OffsetRefractionSample = PdxTex2DLod0( RefractionTexture, ( ScreenPos + RefractionOffset ) / _ScreenResolution );
				float3 OffsetRefractionWorldSpacePos = DecompressWorldSpace( WorldSpacePos, OffsetRefractionSample.a );

				float OffsetStep = step( WorldSpacePos.y, OffsetRefractionWorldSpacePos.y );
				RefractionSample = lerp( OffsetRefractionSample, RefractionSample, OffsetStep );
				RefractionWorldSpacePos = lerp( OffsetRefractionWorldSpacePos, RefractionWorldSpacePos, OffsetStep );
				RefractionDepth = WorldSpacePos.y - RefractionWorldSpacePos.y;

				float2 RefractionWaterColorUV = float2( RefractionWorldSpacePos.x / JOMINIWATER_MapSize.x, 1.0 - RefractionWorldSpacePos.z / JOMINIWATER_MapSize.y );
				float3 RefractionWaterColorMap = PdxTex2D( WaterColorTexture, RefractionWaterColorUV ).rgb * _NightWaterAdjustment;
				RefractionWaterColorMap = lerp( RefractionWaterColorMap, _WaterColorMapTint, _WaterColorMapTintFactor );
				ApplyDevastationWater( RefractionWaterColorMap, WorldSpacePos.xz );
				ApplyDevastationShore( RefractionSample.rgb, WorldSpacePos.xz );

				#if defined( CANAL )
					float HeightDiff = _WaterHeight - GetHeight( WorldSpacePos.xz );
					float CanalDepth = min( pow( 1.0 - HeightDiff, WATER_CANAL_DEPTH_AMP ), WATER_CANAL_DEPTH_MAX );
					float3 Refraction = CalcTerrainUnderwaterSeeThrough( CanalDepth, RefractionWorldSpacePos, RefractionWaterColorMap, RefractionSample.rgb );
				#else
					float3 Refraction = CalcTerrainUnderwaterSeeThrough( RefractionDepth, RefractionWorldSpacePos, RefractionWaterColorMap, RefractionSample.rgb );
				#endif

				#if !defined( RIVER )
					Refraction = lerp( WaterColorMap, Refraction, pow( 1.0 - _WaterZoomedInZoomedOutFactor, 2.0 ) );
				#endif
			#else
				float3 Refraction = WaterColorMap;
			#endif

			return Refraction;
		}

		float4 GameCalcWater( in SWaterParameters Input )
		{
			float4 WaterColorAndSpec = PdxTex2D( WaterColorTexture, Input._WorldUV );
			float GlossMap = WaterColorAndSpec.a;

			float3 ToCamera = CameraPosition.xyz - Input._WorldSpacePos;
			float3 ToCameraDir = normalize( ToCamera );

			// Ocean fade
			float FadeStart = OceanDistanceEnd - OceanDistanceStart;
			float DistanceBlend = FadeStart - CameraPosition.y + OceanDistanceStart;
			DistanceBlend = RemapClamped( DistanceBlend, 0.0, FadeStart, 0.0, 1.0 );

			// OceanWave fade
			FadeStart = OceanWaveDistanceEnd - OceanDistanceStart;
			float WaveDistanceBlend = FadeStart - CameraPosition.y + OceanDistanceStart;
			WaveDistanceBlend = RemapClamped( WaveDistanceBlend, 0.0, FadeStart, 0.0, 0.75 );

			float OceanMap = PdxTex2D( FoamMapTexture, Input._WorldUV ).r;
			float OceanFactor = smoothstep( OceanFadeMin, OceanFadeMax, OceanMap ) * DistanceBlend * OceanFactorMultiplier;

			// Normals
			float2 UVCoord = Input._WorldSpacePos.xz * float2( 1.0, -1.0 ) * Input._NoiseScale;
			float3 NormalMap1 = SampleNormalMapTexture( AmbientNormalTexture, UVCoord, _WaterWave1Scale, _WaterWave1Rotation, JOMINIWATER_GlobalTime * _WaterWave1Speed * Input._WaveSpeedScale, _WaterWave1NormalFlatten * Input._WaveNoiseFlattenMult );
			float3 NormalMap2 = SampleNormalMapTexture( AmbientNormalTexture, UVCoord, _WaterWave2Scale, _WaterWave2Rotation, JOMINIWATER_GlobalTime * _WaterWave2Speed * Input._WaveSpeedScale, _WaterWave2NormalFlatten * Input._WaveNoiseFlattenMult );
			float3 NormalMap3 = SampleNormalMapTexture( AmbientNormalTexture, UVCoord, _WaterWave3Scale, _WaterWave3Rotation, JOMINIWATER_GlobalTime * _WaterWave3Speed * Input._WaveSpeedScale, _WaterWave3NormalFlatten * Input._WaveNoiseFlattenMult );
			float3 Normal = NormalMap1 + NormalMap2 + NormalMap3;

			// Ocean Flow Normal
			Normal = lerp( Normal, Input._FlowNormal, OceanFactor * WaveDistanceBlend );

			// Calculate rotated normal
			#ifdef WATER_LOCAL_SPACE_NORMALS
				float3x3 TBN = Create3x3( Input._Tangent, Input._Bitangent, Input._Normal );
				Normal = normalize( mul( Normal.xzy, TBN ) );
			#else
				Normal = normalize( Normal );
			#endif

			// Calc Depth
			float Depth = Input._Depth;
			#if ( defined( RIVER ) ) && defined( JOMINI_REFRACTION_ENABLED )
				float4 RefractionSample = PdxTex2DLod0( RefractionTexture, Input._ScreenSpacePos.xy / _ScreenResolution );
				float3 RefractionWorldSpacePos = DecompressWorldSpace( Input._WorldSpacePos, RefractionSample.a );
				float RefractionDepth = Input._WorldSpacePos.y - RefractionWorldSpacePos.y;
				Depth = min( Depth, RefractionDepth );
				float WaterFade = 1.0f - saturate( (_WaterFoamShoreMaskDepth - Depth) * _WaterFoamShoreMaskSharpness ) ;
			#else
				float WaterFade = 1.0f - saturate( (_WaterFadeShoreMaskDepth - Depth) * _WaterFadeShoreMaskSharpness ) ;
			#endif

			// Refraction
			float3 Refraction = GameCalcRefraction( Input._WorldSpacePos, Normal, Input._ScreenSpacePos.xy, WaterColorAndSpec.rgb, Input._Depth );

			// Foam
			float FoamFactor = GameCalcFoamFactorWaves( Input._WorldUV, Input._WorldSpacePos.xz, Input._Depth, Input._FlowFoamMask, Input._FlowNormal );
			FoamFactor += GameCalcFoamFactorShore( Input._WorldUV, Input._WorldSpacePos.xz, Input._Depth, Input._FlowFoamMask, Input._FlowNormal );
			FoamFactor += GameCalcFoamFactorCaustics( Input._WorldUV, Input._WorldSpacePos.xz, Input._Depth, Input._FlowFoamMask, Input._FlowNormal );
			FoamFactor += GameCalcOceanWaves( Input._WorldUV, Input._WorldSpacePos.xz, Input._FlowFoamMask, Input._FlowNormal, OceanFactor );

			// Prelight color
			float Facing = 1.0f - max( dot( Normal, ToCameraDir ), 0.0f );
			float3 WaterDiffuse = lerp( _WaterColorDeep, _WaterColorShallow, Facing );
			WaterDiffuse *= _WaterDiffuseMultiplier;

			// Light
			SWaterLightingProperties lightingProperties;
			lightingProperties._WorldSpacePos = Input._WorldSpacePos;
			lightingProperties._ToCameraDir = ToCameraDir;
			lightingProperties._Normal = Normal;
			lightingProperties._Diffuse = WaterDiffuse + FoamFactor;
			lightingProperties._Glossiness = lerp( _WaterGlossBase, GlossMap, _WaterZoomedInZoomedOutFactor );
			lightingProperties._SpecularColor = vec3( _WaterSpecular );
			lightingProperties._NonLinearGlossiness = GetNonLinearGlossiness( lightingProperties._Glossiness ) * _WaterGlossScale;

			// Paralax offset
			float3 ToCam = normalize( CameraPosition - Input._WorldSpacePos );
			float ParalaxDist = ( _FoWCloudHeight + _WaterHeight - Input._WorldSpacePos.y ) / ToCam.y;
			float2 DistortedUV = Input._WorldSpacePos.xz - ToCam.xz * ParalaxDist;

			float Distortion = lerp( CloudReflectionNormalDistortionMin, CloudReflectionNormalDistortionMax, 1.0 - DistanceBlend );
			float NoiseTest = CalcNoise( ( DistortedUV + 0.5 ) * 0.001 * CloudReflectionNoiseUv ) - 0.5;
			DistortedUV += vec2( NoiseTest ) * CloudReflectionDistortion;
			DistortedUV += Normal.xz * Distortion;

			// Cloud reflection
			float Alpha = 1.0 - PdxTex2D( FogOfWarAlpha, ( DistortedUV ) * InverseWorldSize ).r;
			float CloudsAlpha = smoothstep( _FoWCloudsAlphaStart, _FoWCloudsAlphaStop, Alpha ) * _FoWCloudsColor.a ;
			float CloudReflection = SampleFowReflection( DistortedUV );
			float GradientControl = smoothstep( _FoWCloudsColorDayGradientMin, _FoWCloudsColorDayGradientMax, CloudReflection );
			CloudReflection *= CloudReflectionStrength;
			float3 CloudsColor = lerp( _FoWCloudsColorGradient.rgb, _FoWCloudsColor.rgb, GradientControl );
			lightingProperties._Diffuse = lerp( lightingProperties._Diffuse, CloudsColor, CloudReflection * CloudsAlpha * Facing );

			// Ocean gloss
			AdjustOceanSpecular( lightingProperties, OceanFactor );

			// Ocean specular
			float3 DiffuseLight = vec3( 0.0f );
			float3 SpecularLight = vec3( 0.0f );
			CalculateSunLight( lightingProperties, 1.0f, _WaterToSunDir, DiffuseLight, SpecularLight );
			float3 FinalColor = ComposeLight( lightingProperties, 1.0f, _WaterToSunDir, DiffuseLight, SpecularLight * _WaterSpecularFactor );

			FinalColor *= WaterFade;

			// Cubemap reflection
			float3 Reflection = CalcReflection( Normal, ToCameraDir ) * _NightWaterAdjustment;
			float FresnelFactor = Fresnel( abs( dot( lightingProperties._ToCameraDir, Normal ) ), _WaterFresnelBias, _WaterFresnelPow ) * WaterFade;
			FinalColor += lerp( Refraction, Reflection, FresnelFactor );

			// Fade
			#ifdef JOMINIWATER_BORDER_LERP
				float ExtraFade = 1.0f - ( Input._WorldUV.x - 1.0f ) / JOMINIWATER_BorderLerpSize;
				WaterFade *= ExtraFade;
			#endif

			return float4( FinalColor, WaterFade );
		}

		float4 GameCalcWaterPond( in SWaterParameters Input )
		{
			float4 WaterColorAndSpec = PdxTex2D( WaterColorTexture, Input._WorldUV );
			float GlossMap = WaterColorAndSpec.a;

			float3 ToCamera = CameraPosition.xyz - Input._WorldSpacePos;
			float3 ToCameraDir = normalize( ToCamera );

			// Normals
			float2 UVCoord = Input._WorldSpacePos.xz * float2( 1.0, -1.0 ) * Input._NoiseScale * PondNormalUvScale;
			float3 NormalMap1 = SampleNormalMapTexture( AmbientNormalTexture, UVCoord, _WaterWave1Scale, _WaterWave1Rotation, JOMINIWATER_GlobalTime * _WaterWave1Speed * Input._WaveSpeedScale * PondWaveSpeed, _WaterWave1NormalFlatten * Input._WaveNoiseFlattenMult * PondNormalFlatten );
			float3 NormalMap2 = SampleNormalMapTexture( AmbientNormalTexture, UVCoord, _WaterWave2Scale, _WaterWave2Rotation, JOMINIWATER_GlobalTime * _WaterWave2Speed * Input._WaveSpeedScale * PondWaveSpeed, _WaterWave2NormalFlatten * Input._WaveNoiseFlattenMult * PondNormalFlatten );
			float3 NormalMap3 = SampleNormalMapTexture( AmbientNormalTexture, UVCoord, _WaterWave3Scale, _WaterWave3Rotation, JOMINIWATER_GlobalTime * _WaterWave3Speed * Input._WaveSpeedScale * PondWaveSpeed, _WaterWave3NormalFlatten * Input._WaveNoiseFlattenMult * PondNormalFlatten );
			float3 Normal = normalize( NormalMap1 + NormalMap2 + NormalMap3 );

			// Depth Transparency
			float WaterFade = 1.0f - saturate( ( PondDepthScale - Input._Depth) * PondDepthContrast ) ;

			// Color
			float3 WaterColorMap = lerp( WaterColorAndSpec.rgb, _WaterColorMapTint, _WaterColorMapTintFactor ) * _NightWaterAdjustment;

			// Foam
			float FoamFactor = GameCalcPondFoam( Input._WorldUV, Input._WorldSpacePos.xz, Input._Depth, Input._FlowFoamMask, Input._FlowNormal );

			// Prelight color
			float Facing = 1.0f - max( dot( Normal, ToCameraDir ), 0.0f );
			float3 WaterDiffuse = lerp( _WaterColorDeep, _WaterColorShallow, Facing );
			WaterDiffuse *= _WaterDiffuseMultiplier;

			// Light
			SWaterLightingProperties lightingProperties;
			lightingProperties._WorldSpacePos = Input._WorldSpacePos;
			lightingProperties._ToCameraDir = ToCameraDir;
			lightingProperties._Normal = Normal;
			lightingProperties._Diffuse = WaterDiffuse + FoamFactor;
			lightingProperties._Glossiness = lerp( PondGlossScale, GlossMap, _WaterZoomedInZoomedOutFactor );
			lightingProperties._SpecularColor = vec3( PondSpecular );
			lightingProperties._NonLinearGlossiness = GetNonLinearGlossiness( lightingProperties._Glossiness ) * _WaterGlossScale;

			// Ocean specular
			float3 DiffuseLight = vec3( 0.0f );
			float3 SpecularLight = vec3( 0.0f );
			CalculateSunLight( lightingProperties, 1.0f, _WaterToSunDir, DiffuseLight, SpecularLight );
			float3 FinalColor = ComposeLight( lightingProperties, 1.0f, _WaterToSunDir, DiffuseLight, SpecularLight * _WaterSpecularFactor );
			FinalColor *= WaterFade;

			// Cubemap reflection
			float3 Reflection = CalcReflection( Normal, ToCameraDir ) * _NightWaterAdjustment;
			float FresnelFactor = Fresnel( abs( dot( lightingProperties._ToCameraDir, Normal ) ), _WaterFresnelBias, _WaterFresnelPow ) * WaterFade;
			FinalColor += lerp( WaterColorMap, Reflection, FresnelFactor );

			// Fade
			#ifdef JOMINIWATER_BORDER_LERP
				float ExtraFade = 1.0f - ( Input._WorldUV.x - 1.0f ) / JOMINIWATER_BorderLerpSize;
				WaterFade *= ExtraFade;
			#endif

			return float4( FinalColor, WaterFade );
		}

		float4 GameCalcRiver( in VS_OUTPUT_RIVER Input )
		{
			float Depth = CalcDepth( Input.UV );

			SWaterParameters Params;
			Params._ScreenSpacePos = Input.Position;
			Params._WorldSpacePos = Input.WorldSpacePos;
			Params._WorldUV = Input.WorldSpacePos.xz / MapSize;
			Params._WorldUV.y = 1.0f - Params._WorldUV.y;
			Params._Depth = Depth * Input.Width + 0.1f;
			Params._NoiseScale = _NoiseScale;
			Params._WaveSpeedScale = _NoiseSpeed;
			Params._WaveNoiseFlattenMult = _FlattenMult;

			// Flow Movement
			float2 FlowNormalUV = Input.UV.yx * float2( 1.0f, -1.0f );
			FlowNormalUV *= float2( Input.Width, 1.0f ) * _FlowNormalUvScale;
			FlowNormalUV.y += GlobalTime * _FlowNormalSpeed;
			float4 FlowNormalSample = PdxTex2D( FlowNormalTexture, FlowNormalUV );

			float3 FlowNormal = UnpackNormal( FlowNormalSample ).xzy;
			FlowNormal.y *= _WaterFlowNormalFlatten * _FlattenMult * saturate( dot( Input.Normal, float3( 0.0f, 1.0f, 0.0f ) ) );
			Params._FlowNormal = normalize( FlowNormal );
			Params._FlowFoamMask = FlowNormalSample.a * _RiverFoamFactor;

			// Water color
			float4 Color = GameCalcWater( Params );

			// Sampled bottom texture
			float2 BottomUV = float2( Input.UV.x * _TextureUvScale, Input.UV.y );
			float4 BottomDiffuseSample = PdxTex2D( BottomDiffuse, BottomUV );

			// Ocean and river connection fade
			#if defined( JOMINI_REFRACTION_ENABLED )
				Color.a = BottomDiffuseSample.a;
				Color.a *= Input.Transparency * saturate( ( Input.DistanceToMain - 0.1f ) * 5.0f );
			#else
				// Hack to use river bottom textures when refraction is disabled
				float4 BottomPropertiesSample = PdxTex2D( BottomProperties, BottomUV );
				float4 BottomNormalSample = PdxTex2D( BottomNormal, BottomUV );
				float3 BottomNormalUnpacked = UnpackRRxGNormal( BottomNormalSample );

				// Normals
				float3 Normal = normalize( Input.Normal );
				float3 Tangent = normalize( Input.Tangent );
				float3 Bitangent = normalize( cross( Normal, Tangent ) );

				float3x3 TBN = Create3x3( normalize( Tangent ), normalize( Bitangent ), Normal );
				BottomNormalUnpacked = normalize( mul( BottomNormalUnpacked, TBN ) );

				// Light
				float4 ShadowProj = mul( ShadowMapTextureMatrix, float4( Input.WorldSpacePos, 1.0 ) );
				float ShadowTerm = CalculateShadow( ShadowProj, ShadowMap );
				SMaterialProperties MaterialProps = GetMaterialProperties( BottomDiffuseSample.rgb, BottomNormalUnpacked, BottomPropertiesSample.a, BottomPropertiesSample.g, BottomPropertiesSample.b );
				SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, ShadowTerm );
				BottomDiffuseSample.rgb = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );

				// Bottom Color
				Color.rgb = lerp( Color.rgb, BottomDiffuseSample.rgb, saturate( pow( BottomNormalSample.b, 3.0f ) ) );
				Color.a = BottomDiffuseSample.a;
				Color.a *= Input.Transparency * saturate( ( Input.DistanceToMain - 0.1f ) * 5.0f );
			#endif

			// Edge fade
			float EdgeFade1 = smoothstep( 0.0f, _BankFade, Input.UV.y );
			float EdgeFade2 = smoothstep( 0.0f, _BankFade, 1.0f - Input.UV.y );
			Color.a *= EdgeFade1 * EdgeFade2;

			return Color;
		}

	]]
}