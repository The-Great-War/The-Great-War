Includes = {
	"cw/terrain.fxh"
	"cw/utility.fxh"
	"cw/camera.fxh"
	"jomini/jomini_colormap.fxh"
	"jomini/jomini_colormap_constants.fxh"
	"jomini/jomini_province_overlays.fxh"
	"sharedconstants.fxh"
	"constants_game.fxh"
	"coloroverlay_utility.fxh"
}

Code
[[
	//// Powerbloc Constants

	// Needs to match code, see 'enum class EPowerBlocGraphicsType'
	#define POWERBLOC_TYPE_NONE 0
	#define POWERBLOC_TYPE_STANDARD 1
	#define POWERBLOC_TYPE_SELECTED 2
	#define POWERBLOC_TYPE_FADED 3
	#define POWERBLOC_TYPE_INFLUENCE 4

	// Not relevant countries fade
	#define POWERBLOC_OTHER_COUNTRY_FADE 0.95					// Fade amount of all other countries

	// Non selected fade
	#define POWERBLOC_NON_SELECTED_FADE 0.4
	#define POWERBLOC_NON_SELECTED_PATTERN_ALPHA 0.3			// Strength of powerbloc pattern for faded powerblocs

	// Gradient Borders
	#define POWERBLOC_EDGE_WIDTH 0.04							// Gradient border settings
	#define POWERBLOC_EDGE_SHARPNESS 0.005						// Gradient border settings
	#define POWERBLOC_EDGE_ALPHA 1.0							// Gradient border settings
	#define POWERBLOC_EDGE_COLOR_MULTIPLIER 0.7					// Gradient border settings

	#define POWERBLOC_GRADIENT_INSIDE 1.0						// Gradient border settings
	#define POWERBLOC_GRADIENT_OUTSIDE 0.65						// Gradient border settings
	#define POWERBLOC_GRADIENT_WIDTH 0.5						// Gradient border settings

	// Pattern Base Colors
	#define POWERBLOC_BASECOLOR_MULTIPLIER 1.0					// Color multiplier of pattern background
	#define POWERBLOC_BACKGROUND_MULTIPLIER 0.45				// Color multiplier of pattern background

	#define POWERBLOC_PATTERN_ALPHA 0.05						// Strength of powerbloc pattern
	#define POWERBLOC_PATTERN_TILING 7.0						// Size of powerbloc pattern

	#define POWERBLOC_TEAR_MULTIPLIER 0.30						// Color multiplier of cohesion tear background
	#define POWERBLOC_TEAR_TILING 6.0							// Tiling of cohesion tear pattern
	#define POWERBLOC_TEAR_MIN 0.5								// Min value of remapped cohesion tearing
	#define POWERBLOC_TEAR_MAX 1.2								// Max value of remapped cohesion tearing (clamped)
	#define POWERBLOC_TEAR_SHARPNESS 0.1						// Sharpness of cohesion tear remapping

	#define POWERBLOC_NOISE_SHIMMER_UV 24.0						// Size of pattern shimmer
	#define POWERBLOC_NOISE_SHIMMER_SPEED 1.0					// Speed of pattern caustics
	#define POWERBLOC_NOISE_SHIMMER_STRENGTH 0.08				// Strength of pattern shimmer
	#define POWERBLOC_NOISE_SHIMMER_MIN 0.2
	#define POWERBLOC_NOISE_SHIMMER_MAX 1.0

	// Shimmer during powerbloc select mapmode
	#define POWERBLOC_CAUSTIC_SHIMMER_UV 5.0					// Size of caustics shimmer
	#define POWERBLOC_CAUSTIC_SHIMMER_SPEED 0.04				// speed of caustics
	#define POWERBLOC_CAUSTIC_SHIMMER_STRENGTH 0.35				// Strength of caustics

	// Pulse during powerbloc select mapmode
	#define POWERBLOC_PULSE_GLOBAL_SCALE 0.0035					// Scale/Amount of pulses

	#define POWERBLOC_INFLUENCE_COUNTRY_FADE 0.3				// Fade amount of color for countries that have influence pulse

	#define POWERBLOC_PULSE_EDGE_ALPHA 0.25						// Country edge alpha

	#define POWERBLOC_PULSE_OPACITY_MIN 0.1						// Minimum pulse opacity
	#define POWERBLOC_PULSE_OPACITY_MAX 0.4						// Maximum pulse opacity

	#define POWERBLOC_PULSE_INFLUENCE_MAX 1.0					// Influence needed for strongest pulse alpha

	#define POWERBLOC_PULSE_PATTERN_ALPHA 0.15					// Alpha of pattern background

	#define POWERBLOC_PULSE_NOISE_SHIMMER_STRENGTH 1.0			// Strength background pattern
	#define POWERBLOC_PULSE_NOISE_SHIMMER_UV 60.0				// Size noise shimmer
	#define POWERBLOC_PULSE_NOISE_SHIMMER_SPEED 2.0				// Speed noise shimmer
	#define POWERBLOC_PULSE_NOISE_SHIMMER_MIN 0.45
	#define POWERBLOC_PULSE_NOISE_SHIMMER_MAX 0.75

	#define POWERBLOC_PULSE_CAUSTIC_SHIMMER_UV 48.0				// Size of caustics
	#define POWERBLOC_PULSE_CAUSTIC_SHIMMER_STRENGTH 25.0		// Strength of caustics

	#define POWERBLOC_PULSE_COLOR_ADJUST 1.20					// Amount to adjust color of pulse if the underlying pixel is similar color
]]

PixelShader = {

	# PowerBloc Data
	TextureSampler PatternTextures
	{
		Ref = PowerBlocPatternTexturesRef
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		type = "2darray"
	}
	TextureSampler NoiseTearMask
	{
		Index = 12
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/cohesion_tear.dds"
	}
	TextureSampler NoiseTearShadowMask
	{
		Index = 13
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/cohesion_tear_shadow.dds"
	}
	BufferTexture ProvincePowerBlocIdBuffer
	{
		Ref = ProvincePowerBlocId
		type = int
	}
	BufferTexture ProvincePowerBlocTypeBuffer
	{
		Ref = ProvincePowerBlocType
		type = float2
	}
	BufferTexture PowerBlocPosBuffer
	{
		Ref = PowerBlocPos
		type = float2
	}
	BufferTexture PowerBlocColorBuffer
	{
		Ref = PowerBlocColor
		type = float4
	}
	BufferTexture PowerBlocMiscDataBuffer
	{
		Ref = PowerBlocMiscData
		type = float4
	}
	BufferTexture PowerBlocMembersDataBuffer
	{
		Ref = PowerBlocMembers
		type = float4
	}
	BufferTexture PowerBlocUvBuffer
	{
		Ref = PowerBlocUv
		type = float4
	}

	Code
	[[

		int SamplePowerBlocIndex( float2 MapCoords )
		{
			float2 ColorIndex = PdxTex2D( ProvinceColorIndirectionTexture, MapCoords ).rg;
			int Index = ColorIndex.x * 255.0 + ColorIndex.y * 255.0 * 256.0;
			return PdxReadBuffer( ProvincePowerBlocIdBuffer, Index ).r;
		}

		float2 SamplePowerBlocType( float2 MapCoords )
		{
			float2 ColorIndex = PdxTex2D( ProvinceColorIndirectionTexture, MapCoords ).rg;
			int Index = ColorIndex.x * 255.0 + ColorIndex.y * 255.0 * 256.0;
			return PdxReadBuffer2( ProvincePowerBlocTypeBuffer, Index );
		}

		float3 GetPowerBlocColor( int PowerBlocId )
		{
			float3 Color = PdxReadBuffer4( PowerBlocColorBuffer, PowerBlocId ).rgb;
			Color *= POWERBLOC_BASECOLOR_MULTIPLIER;

			return Color;
		}

		float3 GetCausticsPowerbloc( float2 Uv, float Contrast, float Multiplier )
		{
			// Animated Caustics
			Uv.y *= 0.5;

			float3x3 BaseMatrix = Create3x3( -2.0, -1.0, 2.0, 3.0, -2.0, 1.0, 1.0, 2.0, 2.0 );
			float2 CausticsUv = Uv;
			float Speed = POWERBLOC_CAUSTIC_SHIMMER_SPEED;
			float3 a = mul( float3(CausticsUv.x, CausticsUv.y, GlobalTime * Speed ), BaseMatrix );
			float3 b = mul( a, BaseMatrix ) * 0.4;
			float3 c = mul( b, BaseMatrix ) * 0.3;
			float CausticsNoise = float( pow( min( min( length( 0.5 - frac( a ) ), length( 0.5 - frac( b ) ) ), length( 0.5 - frac( c ) ) ), Contrast ) * Multiplier );

			return vec3 ( CausticsNoise );
		}

		float2 GetGradient( float2 Uv, float Time )
		{
			float Random = frac( sin( dot( Uv, float2( 55.123, 46.321 ) ) ) * 43758.5453 );
			float Angle = Random * Time;

			return float2( cos( Angle ), sin( Angle ) );
		}

		float Pseudo3dNoise( float2 Pos, float Time )
		{
			float2 PosFloored = floor( Pos.xy );
			float2 PosLooped = Pos.xy - PosFloored;
			float2 Blend = PosLooped * PosLooped * ( 3.0 - 2.0 * PosLooped );
			float Noise =
				lerp(
					lerp(
						dot( GetGradient( PosFloored + float2( 0, 0 ), Time ), PosLooped - float2( 0, 0 ) ),
						dot( GetGradient( PosFloored + float2( 1, 0 ), Time ), PosLooped - float2( 1, 0 ) ),
						Blend.x ),
					lerp(
						dot( GetGradient( PosFloored + float2( 0, 1 ), Time ), PosLooped - float2( 0, 1 ) ),
						dot( GetGradient( PosFloored + float2( 1, 1 ), Time ), PosLooped - float2( 1, 1 ) ),
						Blend.x ),
				Blend.y
			);

			return 0.5 + 0.5 * Noise;
		}

		float GetPowerBlocPattern( float2 Uv, float3 Color, float Cohesion, int index )
		{
			float2 PatternUv = float2( Uv.x * 2.0, Uv.y ) * POWERBLOC_PATTERN_TILING;
			float Pattern = PdxTex2D( PatternTextures, float3( PatternUv, index ) ).r;

			return Pattern;
		}

		float3 ApplyPowerBlocCohesion( float2 Uv, float Cohesion, float3 Color, float3 BaseColor )
		{
			Uv.y = 1.0 - Uv.y;

			float TearNoise1 = PdxTex2D( NoiseTearMask, float2( Uv.x * 2.0, Uv.y ) * POWERBLOC_TEAR_TILING ).r;
			float TearNoise2 = PdxTex2D( NoiseTearMask, float2( Uv.x * 2.0, Uv.y ) * POWERBLOC_TEAR_TILING ).g;
			float TearNoise3 = PdxTex2D( NoiseTearMask, float2( Uv.x * 2.0, Uv.y ) * POWERBLOC_TEAR_TILING ).b;

			float TearNoiseShadow1 = PdxTex2D( NoiseTearShadowMask, float2( Uv.x * 2.0, Uv.y ) * POWERBLOC_TEAR_TILING ).r;
			float TearNoiseShadow2 = PdxTex2D( NoiseTearShadowMask, float2( Uv.x * 2.0, Uv.y ) * POWERBLOC_TEAR_TILING ).g;
			float TearNoiseShadow3 = PdxTex2D( NoiseTearShadowMask, float2( Uv.x * 2.0, Uv.y ) * POWERBLOC_TEAR_TILING ).b;

			// High cohesion
			float TearMask = lerp( 1.0, TearNoise1, step( Cohesion, 0.75 ) );
			float TearMaskShadow = lerp( 1.0, TearNoiseShadow1, step( Cohesion, 0.75 ) );

			// Mid cohesion
			TearMask = lerp( TearMask, TearNoise2, step( Cohesion, 0.5 ) );
			TearMaskShadow = lerp( TearMaskShadow, TearNoiseShadow2, step( Cohesion, 0.5 ) );

			// Low cohesion
			TearMask = lerp( TearMask, TearNoise3, step( Cohesion, 0.25 ) );
			TearMaskShadow = lerp( TearMaskShadow, TearNoiseShadow3, step( Cohesion, 0.25 ) );

			float3 TearColor = lerp( BaseColor * POWERBLOC_BACKGROUND_MULTIPLIER * TearMaskShadow, Color, TearMask );

			return TearColor;
		}

		void ApplyPowerBlocOverlay( inout float3 OutColor, float Alpha, float2 MapCoords, float2 WorldSpacePosXz )
		{
			float3 CountryColor = OutColor;

			// Custom gradient border values
			float DistanceFieldValue = CalcDistanceFieldValue( MapCoords );
			float Edge = smoothstep( POWERBLOC_EDGE_WIDTH + POWERBLOC_EDGE_SHARPNESS, POWERBLOC_EDGE_WIDTH, DistanceFieldValue );

			// Buffer Data
			int PowerBlocId = SamplePowerBlocIndex( MapCoords );
			float4 PowerBlocMiscData = PdxReadBuffer4( PowerBlocMiscDataBuffer, PowerBlocId );
			float2 PowerBlocPos = PdxReadBuffer2( PowerBlocPosBuffer, PowerBlocId );
			float PowerBlocCohesion = RemapClamped( PowerBlocMiscData.z, 0.0, 100.0, 0.0, 1.0 );
			int PowerBlocPatternIndex = (int)PowerBlocMiscData.w;

			// PowerBloc Opacity Filtering
			float PowerBlocOpacity = 1.0f;
			float2 Pixel = MapCoords * IndirectionMapSize + 0.5;
			float2 FracCoord = frac( Pixel );
			Pixel = floor( Pixel ) / IndirectionMapSize - InvIndirectionMapSize / 2.0;
			float C11 = SamplePowerBlocIndex( Pixel );
			float C21 = SamplePowerBlocIndex( Pixel + float2( InvIndirectionMapSize.x, 0.0) );
			float C12 = SamplePowerBlocIndex( Pixel + float2( 0.0, InvIndirectionMapSize.y) );
			float C22 = SamplePowerBlocIndex( Pixel + InvIndirectionMapSize );
			float x1 = lerp( 1.0 + C11,  1.0 + C21, FracCoord.x );
			float x2 = lerp(  1.0 + C12,  1.0 + C22, FracCoord.x );
			PowerBlocOpacity = RemapClamped( lerp( x1, x2, FracCoord.y ), 0.5f, 0.75f, 0.0f, 1.0f );

			// PowerBloc Type Filtering
			float2 T11 = SamplePowerBlocType( Pixel );
			float2 T21 = SamplePowerBlocType( Pixel + float2( InvIndirectionMapSize.x, 0.0) );
			float2 T12 = SamplePowerBlocType( Pixel + float2( 0.0, InvIndirectionMapSize.y) );
			float2 T22 = SamplePowerBlocType( Pixel + InvIndirectionMapSize );

			// Standard
			float Tx1 = lerp( T11.r == POWERBLOC_TYPE_STANDARD, T21.r == POWERBLOC_TYPE_STANDARD, FracCoord.x );
			float Tx2 = lerp( T12.r == POWERBLOC_TYPE_STANDARD, T22.r == POWERBLOC_TYPE_STANDARD, FracCoord.x );
			float PowerBlocStandard = lerp( Tx1, Tx2, FracCoord.y );

			// Selected
			Tx1 = lerp( T11.r == POWERBLOC_TYPE_SELECTED, T21.r == POWERBLOC_TYPE_SELECTED, FracCoord.x );
			Tx2 = lerp( T12.r == POWERBLOC_TYPE_SELECTED, T22.r == POWERBLOC_TYPE_SELECTED, FracCoord.x );
			float PowerBlocSelected = lerp( Tx1, Tx2, FracCoord.y );

			// Fade
			Tx1 = lerp( T11.r == POWERBLOC_TYPE_FADED, T21.r == POWERBLOC_TYPE_FADED, FracCoord.x );
			Tx2 = lerp( T12.r == POWERBLOC_TYPE_FADED, T22.r == POWERBLOC_TYPE_FADED, FracCoord.x );
			float PowerBlocFaded = lerp( Tx1, Tx2, FracCoord.y );

			// Influence
			Tx1 = lerp( T11.r == POWERBLOC_TYPE_INFLUENCE, T21.r == POWERBLOC_TYPE_INFLUENCE, FracCoord.x );
			Tx2 = lerp( T12.r == POWERBLOC_TYPE_INFLUENCE, T22.r == POWERBLOC_TYPE_INFLUENCE, FracCoord.x );
			float PowerBlocInfluence = lerp( Tx1, Tx2, FracCoord.y );

			// PowerBloc Color Filtering
			float3 Pc11 = GetPowerBlocColor( int( C11 ) );
			float3 Pc21 = GetPowerBlocColor( int( C21 ) );
			float3 Pc12 = GetPowerBlocColor( int( C12 ) );
			float3 Pc22 = GetPowerBlocColor( int( C22 ) );
			float3 Px1 = lerp( Pc11, Pc21, FracCoord.x );
			float3 Px2 = lerp( Pc12, Pc22, FracCoord.x );
			float3 BaseColor = lerp( Px1, Px2, FracCoord.y);
			float3 PowerBlocColor = BaseColor * POWERBLOC_BACKGROUND_MULTIPLIER;

			// Textures
			float Pattern = GetPowerBlocPattern( MapCoords, PowerBlocColor, PowerBlocCohesion, PowerBlocPatternIndex );

			// Noise
			float2 NoiseUv = float2( MapCoords.x * 2.0, MapCoords.y ) * POWERBLOC_NOISE_SHIMMER_UV;
			float AnimatedNoise = Pseudo3dNoise( NoiseUv, GlobalTime * POWERBLOC_NOISE_SHIMMER_SPEED );
			AnimatedNoise = smoothstep( POWERBLOC_NOISE_SHIMMER_MIN, POWERBLOC_NOISE_SHIMMER_MAX, AnimatedNoise );

			// Pattern
			float3 PatternColor = BaseColor * Pattern;
			float3 PatternShimmer = PatternColor * AnimatedNoise * POWERBLOC_NOISE_SHIMMER_STRENGTH;
			float3 CausticShimmer = PatternColor * GetCausticsPowerbloc( MapCoords * POWERBLOC_CAUSTIC_SHIMMER_UV, 3.0, 15.0 ) * POWERBLOC_CAUSTIC_SHIMMER_STRENGTH;

			PowerBlocColor = lerp( PowerBlocColor, BaseColor, Pattern * lerp( POWERBLOC_PATTERN_ALPHA, POWERBLOC_NON_SELECTED_PATTERN_ALPHA, PowerBlocSelected ) );
			float3 ColorWithPattern = PowerBlocColor;

			PowerBlocColor = lerp( PowerBlocColor, PowerBlocColor + PatternShimmer, saturate( PowerBlocStandard + PowerBlocSelected ) );
			PowerBlocColor = lerp( PowerBlocColor, PowerBlocColor + CausticShimmer, PowerBlocSelected );
			PowerBlocColor = lerp( PowerBlocColor, ColorWithPattern * POWERBLOC_EDGE_COLOR_MULTIPLIER, Edge );


			//// Apply base powerbloc colors ////
			// Apply Cohesion
			PowerBlocColor = ApplyPowerBlocCohesion( MapCoords, PowerBlocCohesion, PowerBlocColor, BaseColor );

			// Apply Faded powerbloc
			PowerBlocColor = lerp( PowerBlocColor, vec3( 0.7 ), POWERBLOC_NON_SELECTED_FADE * PowerBlocFaded );

			// Apply Non powerbloc countries
			float3 OtherCountryColor = lerp( BaseColor, vec3( 0.7 ), POWERBLOC_OTHER_COUNTRY_FADE );
			OutColor = lerp( OtherCountryColor, PowerBlocColor, PowerBlocOpacity );


			//// Influence pulse ////
			float3 InfluenceCountryColor = lerp( CountryColor, vec3( 0.7 ), POWERBLOC_INFLUENCE_COUNTRY_FADE );
			OutColor = lerp( OutColor, InfluenceCountryColor, PowerBlocInfluence );

			// Leverage values
			float Lx1 = lerp( T11.g, T21.g, FracCoord.x );
			float Lx2 = lerp( T12.g, T22.g, FracCoord.x );
			float PowerBlocLeverage = lerp( Lx1, Lx2, FracCoord.y );
			PowerBlocLeverage = RemapClamped( PowerBlocLeverage, 0.0, POWERBLOC_PULSE_INFLUENCE_MAX, 0.25, 1.0 );

			// Similar color to country adjustments
			float DeltaR = abs( CountryColor.r - BaseColor.r );
			float DeltaG = abs( CountryColor.g - BaseColor.g );
			float DeltaB = abs( CountryColor.b - BaseColor.b );
			if ( DeltaR < 0.1 && DeltaG < 0.1 && DeltaB < 0.1 )
			{
				PowerBlocColor *= POWERBLOC_PULSE_COLOR_ADJUST;
			}

			float BaseGradient = distance( PowerBlocPos.xy, WorldSpacePosXz );
			float TimeScale = -GlobalTime * 0.2;
			float GradientScale = BaseGradient * POWERBLOC_PULSE_GLOBAL_SCALE;
			float Ripple = frac( TimeScale + GradientScale );
			Ripple += RemapClamped( Ripple, 0.05, 0.0, 0.0, 1.0 );
			Ripple = smoothstep( 0.4, 1.0, Ripple );

			float2 PulseNoiseUv = float2( MapCoords.x * 2.0, MapCoords.y );
			float PulseAnimatedNoise = Pseudo3dNoise( PulseNoiseUv * POWERBLOC_PULSE_NOISE_SHIMMER_UV, GlobalTime * POWERBLOC_PULSE_NOISE_SHIMMER_SPEED );
			PulseAnimatedNoise = smoothstep( POWERBLOC_PULSE_NOISE_SHIMMER_MIN, POWERBLOC_PULSE_NOISE_SHIMMER_MAX, PulseAnimatedNoise );

			float3 NoiseShimmer = PatternColor * PulseAnimatedNoise * Ripple;
			float3 PulseCausticShimmer = PatternColor * GetCausticsPowerbloc( MapCoords * POWERBLOC_PULSE_CAUSTIC_SHIMMER_UV, 7.0, 3.0 ) * Ripple;

			PowerBlocColor = lerp( PowerBlocColor, BaseColor, Pattern * POWERBLOC_PULSE_PATTERN_ALPHA * lerp( POWERBLOC_PATTERN_ALPHA, POWERBLOC_NON_SELECTED_PATTERN_ALPHA, PowerBlocFaded ) );
			PowerBlocColor = lerp( PowerBlocColor, PowerBlocColor + NoiseShimmer, ( 1.0 - Edge ) * POWERBLOC_PULSE_NOISE_SHIMMER_STRENGTH );
			PowerBlocColor = lerp( PowerBlocColor, PowerBlocColor + PulseCausticShimmer, ( 1.0 - Edge ) * POWERBLOC_PULSE_CAUSTIC_SHIMMER_STRENGTH );

			float InfluenceOpacity = lerp( POWERBLOC_PULSE_OPACITY_MIN, POWERBLOC_PULSE_OPACITY_MAX, PowerBlocLeverage );
			OutColor = lerp( OutColor, PowerBlocColor * Ripple, Ripple * InfluenceOpacity * PowerBlocInfluence );
			OutColor = lerp( OutColor, BaseColor * POWERBLOC_EDGE_COLOR_MULTIPLIER, Edge * POWERBLOC_PULSE_EDGE_ALPHA * PowerBlocInfluence );

			//// Apply final Edge fixes ////
			OutColor = lerp( vec3( 0.0 ), OutColor, Alpha );
		}
	]]
}