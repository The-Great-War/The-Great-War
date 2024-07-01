Includes = {
	"jomini/jomini_vertical_border.fxh"
	"cw/utility.fxh"
	"fog_of_war.fxh"
	"distance_fog.fxh"
	"pdxverticalborder.fxh"
	"dynamic_masks.fxh"
}


VertexShader =
{
	MainCode VS_Standard
	{
		Input = "VS_INPUT_PDX_BORDER"
		Output = "VS_OUTPUT_PDX_BORDER"
		Code
		[[
			float3 DisplaceUpperVertices( float3 Pos, float UVY )
			{
				float UpperVertexMask = ( 1.0f - UVY );

				float PositionKey = Pos.x + Pos.y + Pos.z;

				float Displacement = VERTEX_DISPLACEMENT_MAGNITUDE * UpperVertexMask * sin( PositionKey + sin( GlobalTime * VERTEX_DISPLACEMENT_SPEED ) );

				float3 Result = Pos;
				Result.y += Displacement;
				return( Result );
			}

			PDX_MAIN
			{
				VS_OUTPUT_PDX_BORDER Out;

				Out.DistanceToStart = Input.DistanceToStart;
				Out.DistanceToEnd = Input.DistanceToEnd;
				Out.UV0 = ScaleAndAnimateUV( Input.UV, UVScale0, UVSpeed0 );
				Out.WorldSpacePos = ScaleAndExtrudePosition( Input.Position, Input.Extrusion );
				Out.WorldSpacePos = DisplaceUpperVertices(Out.WorldSpacePos.rgb, Input.UV.y);
				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4(Out.WorldSpacePos, 1.0f) );

			#ifdef PDX_BORDER_UV1
				Out.UV1 = ScaleAndAnimateUV( Input.UV, UVScale1, UVSpeed1 * UV01_SPEED );
			#endif

			#ifdef PDX_BORDER_UV2
				Out.UV2 = ScaleAndAnimateUV( Input.UV, UVScale2, UVSpeed2 * UV02_SPEED );
			#endif

			#ifdef PDX_BORDER_UV3
				Out.UV3 = ScaleAndAnimateUV( Input.UV, UVScale3, UVSpeed3 * UV03_SPEED );
			#endif
				return Out;
			}
		]]
	}

}

PixelShader =
{
	Code
	[[
		// Cell center from point on the grid
		float2 VoronoiPointFromRoot( in float2 root, in float deg )
		{
			float2 p = Hash2_2( root ) - 0.5f;
			float s = sin( deg );
			float c = cos( deg );
			p = mul( Create2x2( s, c, -c,  s ), p ) * 0.66f;
			p += root + 0.5f;
			return p;
		}

		// Voronoi cell point rotation degrees
		float DegFromRootUV( in float2 uv )
		{
			return GlobalTime * ANIMATION_SPEED * ( Hash1_2( uv ) - 0.5f ) * 2.0f;
		}

		float2 RandomAround2_2( in float2 p, in float2 range, in float2 uv )
		{
			return p + ( Hash2_2( uv ) - 0.5f ) * range;
		}

		float4 ApplyVerticalBordersFog( float4 Diffuse, float3 WorldSpacePos )
		{
			Diffuse.rgb = ApplyFogOfWar( Diffuse.rgb, WorldSpacePos, 0.0 );
			Diffuse.rgb = GameApplyDistanceFog( Diffuse.rgb, WorldSpacePos );
			Diffuse.a *= Alpha;

			return Diffuse;
		}

		float3 FireParticles( in float2 uv, in float2 originalUV )
		{
			float3 particles = vec3( 0.0f );
			float2 rootUV = floor( uv );
			float deg = DegFromRootUV( rootUV );
			float2 pointUV = VoronoiPointFromRoot( rootUV, deg );
			float dist = 2.0f;
			float distBloom = 0.0f;

			// UV manipulation for the faster particle movement
			float2 tempUV = uv + ( Noise2_2( uv * 2.0f ) - 0.5f ) * 0.1f;
			tempUV += -( Noise2_2( uv * 3.0f + GlobalTime ) - 0.5f ) * 0.07f;

			// Sparks sdf
			dist = length( Rotate( tempUV - pointUV, 0.25f ) * RandomAround2_2( PARTICLE_SCALE, PARTICLE_SCALE_VAR, rootUV ) );

			// Bloom sdf
			distBloom = length( Rotate( tempUV - pointUV, 0.25f ) * RandomAround2_2( PARTICLE_BLOOM_SCALE, PARTICLE_BLOOM_SCALE_VAR, rootUV ) );

			// Add sparks
			particles += ( 1.0f - smoothstep(PARTICLE_SIZE * 0.6f, PARTICLE_SIZE * 1.0f, dist) ) * SPARK_COLOR;

			// Add bloom
			particles += pow( ( 1.0f - smoothstep(0.0f, PARTICLE_SIZE * 4.0f, distBloom ) ) * 1.0f, 3.0f ) * BLOOM_COLOR;

			// Upper disappear curve randomization
			float border = ( Hash1_2( rootUV ) - 0.5f ) * 1.0f;
			float disappear = 1.0f - smoothstep( border, border + 0.05f, 1.0f - originalUV.y );

			// Lower appear curve randomization
			border = ( Hash1_2( rootUV + 0.214f ) ) * 0.2f;
			float appear = smoothstep( border, border + 0.1f, 1.0f - originalUV.y );

			return particles * disappear * appear;
		}

		//Layering particles to imitate 3D view
		float3 LayeredParticles(in float2 uv, in float sizeMod, in float alphaMod, in int layers, in float smoke)
		{
			float3 particles = vec3( 0.0f );
			float size = 1.0f;
			float alpha = 1.0f;
			float2 offset = float2( 0.0f, 0.0f );
			float2 noiseOffset;
			float2 bokehUV;

			for ( int i = 0; i < layers; i++ )
			{
				// Particle noise movement
				noiseOffset = ( Noise2_2( uv * size * 2.0f + 0.5f ) - 0.5f ) * 0.1f;

				// UV with applied movement
				bokehUV = ( uv * size + GlobalTime * MOVEMENT_DIRECTION * MOVEMENT_SPEED ) + offset + noiseOffset;

				// Adding particles
				particles += FireParticles( bokehUV, uv ) * alpha * ( ( float( i ) / float( layers ) ) );

				// Moving uv origin to avoid generating the same particles
				offset += Hash2_2( float2( alpha, alpha ) );

				// Next layer modification
				alpha *= alphaMod;
				size *= sizeMod;
			}

			return particles;
		}
	]]

	MainCode PixelShader_1x
	{
		Input = "VS_OUTPUT_PDX_BORDER"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float4 TexColor0 = PdxTex2D( BorderTexture0, Input.UV0 );
				float3 Diffuse = CalculateLayerColor( TexColor0.rgb, Color.rgb );

				return ApplyVerticalBordersFog( float4( Diffuse, TexColor0.a ), Input.WorldSpacePos );
			}
		]]
	}

	MainCode PS_Vertical_Warborder
	{
		Input = "VS_OUTPUT_PDX_BORDER"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				// Find control settings in pdxverticalborder.fxh
				float4 Diffuse = vec4( 0.0 );
				float2 UV = CalcDetailUV( float2( Input.WorldSpacePos.x, Input.WorldSpacePos.z ) );

				// Border edge alpha
				float FadeDistance = min( 15.0f, Input.DistanceToStart + Input.DistanceToEnd );
				float EdgeFade = saturate( Input.DistanceToStart / FadeDistance ) * saturate( Input.DistanceToEnd / FadeDistance );
				float EdgeAlpha = saturate( pow( EdgeFade * 1.0f, 1.2f ) );

				// Particles
				float TopAlpha2 = LevelsScan( Input.UV0.y, LAYER2_TOPALPHA_POSITION, LAYER1_TOPALPHA_CONTRAST );
				float3 ParticlesCol = saturate( LayeredParticles( Input.UV0, SIZE_MOD, ALPHA_MOD, LAYERS_COUNT, 1.0f ) );
				float ParticlesAlpha = ( ( ParticlesCol.r + ParticlesCol.g + ParticlesCol.b ) / 3.0f ) * TopAlpha2;

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
				float PanningNoise = PdxTex2D( DevastationPollution, float3( UV01, DevastationTexIndex + DevastationTexIndexOffset ) ).a;

				// Adjust noise values
				PanningNoise = 1.0 - max( smoothstep( 0.0, 1.0, PanningNoise ), 0.3 );
				float InnerEdgeFade = 1.0 - RemapClamped( Input.UV0.y, PanningNoise, PanningNoise + 0.5, 0.0, 1.0 );

				// Low-flame values from noise variation
				float UpperEdgeHeight = lerp( UPPER_EDGE_HEIGHT, UPPER_EDGE_HEIGHT_LOW, InnerEdgeFade );
				float FlameOpacity = lerp( OPACITY, OPACITY_LOW, InnerEdgeFade );
				float FlameTexSharpness = lerp( ALPHA_SHARPNESS, ALPHA_SHARPNESS_LOW, InnerEdgeFade );
				float MaxFlameLutCoord = lerp( MAX_FLAME_LUT_COORD, MAX_LUT_COORD_LOW, InnerEdgeFade );

				// Uppder edge fadeout
				float UpperEdgeFade = Input.UV0.y;
				UpperEdgeFade = RemapClamped( UpperEdgeFade, saturate( UpperEdgeHeight ), 1.0, 0.0, 1.0 );

				// Lower edge fadeout
				float LowerEdgeMask = saturate( Input.UV0.y - LOWER_EDGE_FALLOFF );
				float4 LowerEdgeTextureSample = PdxTex2D( BorderTexture0, float2( Input.UV1.x, Input.UV1.y  ) * UV_DIST_SCALE );

				// Textures
				float2 BaseUV = float2( Input.UV3.x, Input.UV3.y ) * 1.5f;
				float4 BorderTextureDistorted = PdxTex2D( BorderTexture0, BaseUV );

				float2 DistortedUVs = BaseUV + float2( LowerEdgeTextureSample.r, LowerEdgeTextureSample.g ) * UV_DIST_STRENGTH;
				float4 BorderTextureDistorted2 = PdxTex2D( BorderTexture0, DistortedUVs * 1.0f );

				BorderTextureDistorted *= BorderTextureDistorted2;

				// Texture Masks for the Lower Edge of the Vertical border
				float2 LowerDistortedUVs = BaseUV + float2( LowerEdgeTextureSample.r, LowerEdgeTextureSample.g ) * UV_DIST_STRENGTH;
				float4 LowerEdgeTexture = PdxTex2D( BorderTexture0, LowerDistortedUVs );
				float LowerCut = smoothstep( LOWER_EDGE_MIN, LOWER_EDGE_MAX, LowerEdgeMask * LowerEdgeMask );

				// Color
				float ColorTexture = BorderTextureDistorted.a;
				ColorTexture = RemapClamped( ColorTexture, 0.0, COLOR_SMOOTHNESS, COLOR_MIN, 1.0 );
				float LutCoord = ColorTexture + LowerEdgeMask + ParticlesCol;
				LutCoord = RemapClamped( LutCoord, 0.0, 1.0, 0.0, MaxFlameLutCoord );

				float3 FlameColor = PdxTex2D( VerticalBorderLUT, saturate( float2( LutCoord, 0.0 ) ) ).rgb;

				float3 HSV_ = RGBtoHSV( FlameColor );
				HSV_.y *= COLOR_SATURATION;
				FlameColor = HSVtoRGB( HSV_ );

				// Emissive
				FlameColor *= COLOR_EMISSIVE;

				// Alpha
				float HeightTexFade = BorderTextureDistorted2.a;
				HeightTexFade = RemapClamped( HeightTexFade, FlameTexSharpness - UpperEdgeFade, 1.0, 0.0, 1.0 );

				float Alpha = saturate( ParticlesAlpha + UpperEdgeFade * HeightTexFade );
				Alpha = saturate( Alpha - LowerCut );
				Alpha *= FlameOpacity * EdgeAlpha * ( 1.0f - _FlatmapLerp );

				// Output
				Diffuse.rgb = FlameColor;
				Diffuse.a = Alpha;
				return ApplyVerticalBordersFog( Diffuse, Input.WorldSpacePos );
			}
		]]
	}

	MainCode PS_Vertical_Escalation_Border
	{
		Input = "VS_OUTPUT_PDX_BORDER"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				// Find control settings in pdxverticalborder.fxh
				float4 Diffuse = vec4( 0.0 );
				float2 UV = CalcDetailUV( float2( Input.WorldSpacePos.x, Input.WorldSpacePos.z ) );

				// Textures
				float2 UvPanning01 = GlobalTime * SMOKE_TEXTURE_PAN_SPEED_01;
				float2 UvPanning02 = GlobalTime * SMOKE_TEXTURE_PAN_SPEED_02;
				float2 Uv01 =  Input.UV0 + UvPanning01;
				float2 Uv02 =  Input.UV0 + UvPanning02;

				// UV & UV Panning Properties
				float2 NoiseUvPanning01 = GlobalTime * SMOKE_NOISE_PAN_SPEED_01;
				float2 NoiseUvPanning02 = GlobalTime * SMOKE_NOISE_PAN_SPEED_02;
				float2 NoiseUvPanning03 = GlobalTime * SMOKE_NOISE_PAN_SPEED_03;
				float2 NoiseUv01 = Input.UV0 + NoiseUvPanning01;
				float2 NoiseUv02 = Input.UV0 + NoiseUvPanning02;
				float2 NoiseUv03 = Input.UV0 + NoiseUvPanning03;

				// Noise
				float Noise01 = vec3( ToLinear( PdxTex2D( DevastationPollution, NoiseUv01 * SMOKE_NOISE_UV_01 ).a ) );
				float Noise02 = vec3( ToLinear( PdxTex2D( BorderTexture0, NoiseUv02 * SMOKE_NOISE_UV_02 ).a ) );
				float Noise03 = vec3( ToLinear( PdxTex2D( BorderTexture0, NoiseUv03 * SMOKE_NOISE_UV_03 ).a ) );
				float NoiseSum = Noise01 + Noise02 + Noise03;
				NoiseSum = smoothstep( -0.5, 1.0, NoiseSum );

				// Color
				float Color01 = vec3( PdxTex2D( BorderTexture0, Uv01 * SMOKE_TEXTURE_UV_01 + NoiseSum * SMOKE_TEXTURE_DISTORTION ).r );
				float Color02 = vec3( PdxTex2D( BorderTexture0, Uv02 * SMOKE_TEXTURE_UV_02 + NoiseSum * SMOKE_TEXTURE_DISTORTION ).b );

				float3 Color = SoftLight( Color01, Color02 );
				Color = Overlay( Color, SMOKE_TINT );

				// Alpha
				float FadeDistance = min( 15.0f, Input.DistanceToStart + Input.DistanceToEnd );
				float EdgeFade = saturate( Input.DistanceToStart / FadeDistance ) * saturate( Input.DistanceToEnd / FadeDistance );
				float EdgeAlpha = saturate( pow( EdgeFade, 1.2f ) );
				float LowerEdgeMask = saturate( Input.UV0.y - SMOKE_LOWER_EDGE_FALLOFF );
				float LowerCut = smoothstep( SMOKE_LOWER_EDGE_MIN,  SMOKE_LOWER_EDGE_MAX, LowerEdgeMask * LowerEdgeMask );

				float Height = smoothstep( SMOKE_TEXTURE_HEIGHT_MIN, SMOKE_TEXTURE_HEIGHT_MAX, Input.UV0.y );
				float Alpha = saturate( Height * NoiseSum );
				Alpha = saturate( Alpha - LowerCut );
				Alpha *= EdgeAlpha * ( 1.0f - _FlatmapLerp );

				// Output
				Diffuse.rgb = Color;
				Diffuse.a = Alpha;
				return ApplyVerticalBordersFog( Diffuse, Input.WorldSpacePos );
			}
		]]
	}
}

Effect VerticalBorder_1x
{
	VertexShader = "VertexShader_1x"
	PixelShader = "PixelShader_1x"
}

Effect Vertical_War_Border
{
	VertexShader = "VS_Standard"
	PixelShader = "PS_Vertical_Warborder"
	Defines = { "PDX_BORDER_UV1" "PDX_BORDER_UV2" "PDX_BORDER_UV3" }
}

Effect Vertical_Escalation_Border
{
	VertexShader = "VS_Standard"
	PixelShader = "PS_Vertical_Escalation_Border"
	Defines = { "PDX_BORDER_UV1" "PDX_BORDER_UV2" "PDX_BORDER_UV3" }
}
