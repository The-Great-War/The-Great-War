Includes = {
	"cw/lines.fxh"
	"cw/utility.fxh"
	"cw/camera.fxh"
	"cw/random.fxh"
	"jomini/jomini_lighting.fxh"
}

VertexShader =
{
	MainCode VS_strategic_objective_arrow
	{
		Input = "VS_INPUT3D"
		Output = "VS_OUTPUT_PDXLINES"
		Code
		[[
			PDX_MAIN
			{
				VS_PDXLINES Out;

				Out.Bitangent = cross( Input.Normal, Input.Tangent );
				float3 SideVec = Out.Bitangent * ( ( ( Input.VertexID % 2 ) == 0 ) ? 1.0 : -1.0 );

				Out.WorldSpacePos = Input.Position + SideVec * Width * 0.5;

				Out.Position = FixProjectionAndMul( ViewProjectionMatrix, float4( Out.WorldSpacePos, 1.0 ) );
				Out.Normal = Input.Normal;
				Out.Tangent = Input.Tangent;
				Out.UV0To1 = Input.UV;

				Out.UV = Input.UV * UVScale;

				Out.MaskUV = Input.UV * MaskUVScale;
				Out.MaskUV.x *= LineLength;

				return PdxLinesConvertOutput( Out );
			}
		]]
	}
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
	TextureSampler NormalTexture
	{
		Ref = PdxTexture1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler PropertiesTexture
	{
		Ref = PdxTexture2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler MaskTexture
	{
		Ref = PdxTexture3
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}



	MainCode PS_strategic_objective_arrow
	{
		Input = "VS_OUTPUT_PDXLINES"
		Output = "PDX_COLOR"
		Code
		[[
			float2 GetRandomizedUv( float2 FlooredUv, float2 Uv, float2 OffsetDir, float OffsetScale )
			{
				FlooredUv += OffsetDir;
				float RandomX = CalcRandom( FlooredUv ) * OffsetScale;
				float2 NudgedSeed = float2( FlooredUv.x + 12.0, FlooredUv.y + 65.0 );
				float RandomY = CalcRandom( NudgedSeed ) * OffsetScale;
				float2 Random = float2( RandomX, RandomY );
				return Uv - OffsetDir - Random;
			}

			// Inner arrow settings
			#define InnerUvTiling 4.5	// Tiling of arrows
			#define InnerUvScale 0.75	// Scale of arrows
			#define RandomScale 0.5		// Distance modifier of random offset

			PDX_MAIN
			{
				float ProgressFactor = Progress - Input.UV0To1.x;
				clip( ProgressFactor );

				// Main texture
				float4 Diffuse = PdxTex2D( DiffuseTexture, Input.UV );

				// Smaller arrows uv
				float2 InnerUv = ( Input.UV - 0.5 ) * InnerUvTiling;
				InnerUv = InnerUv + 0.5;
				InnerUv.x = InnerUv.x - AnimationTime * UVOffsetScale * InnerUvTiling;

				// Store dxdy
				float2 dx = ddx( InnerUv );
				float2 dy = ddy( InnerUv );

				// Store floored uv
				float2 InnerUvFloored = floor( InnerUv );
				InnerUv = InnerUv - InnerUvFloored;

				float2 InnerUvOffset0 =  GetRandomizedUv( InnerUvFloored, InnerUv, float2( 0.0, 0.0 ), RandomScale ) * InnerUvScale;
				float2 InnerUvOffset1 =  GetRandomizedUv( InnerUvFloored, InnerUv, float2( 0.0, -1.0 ), RandomScale ) * InnerUvScale;
				float2 InnerUvOffset2 =  GetRandomizedUv( InnerUvFloored, InnerUv, float2( -1.0, 0.0 ), RandomScale ) * InnerUvScale;
				float2 InnerUvOffset3 =  GetRandomizedUv( InnerUvFloored, InnerUv, float2( -1.0, -1.0 ), RandomScale ) * InnerUvScale;

				float4 InnerDiffuse = PdxTex2DGrad( NormalTexture, InnerUvOffset0, dx, dy );
				float4 InnerDiffuse1 = PdxTex2DGrad( NormalTexture, InnerUvOffset1, dx, dy );
				float4 InnerDiffuse2 = PdxTex2DGrad( NormalTexture, InnerUvOffset2, dx, dy );
				float4 InnerDiffuse3 = PdxTex2DGrad( NormalTexture, InnerUvOffset3, dx, dy );

				InnerDiffuse = lerp( InnerDiffuse, InnerDiffuse1, InnerDiffuse1.r );
				InnerDiffuse = lerp( InnerDiffuse, InnerDiffuse2, InnerDiffuse2.r );
				InnerDiffuse = lerp( InnerDiffuse, InnerDiffuse3, InnerDiffuse3.r );

				Diffuse *= TintColor;
				InnerDiffuse *= TintColor * 7.0;

				InnerDiffuse.a = saturate( lerp( 0.0, InnerDiffuse.a * InnerDiffuse.r, Diffuse.r * 1.0 ) );
				Diffuse = lerp( Diffuse, InnerDiffuse, InnerDiffuse.a );

				float4 Mask = SampleMask( Input.MaskUV, MaskTexture );

				return float4( Diffuse * Mask );
			}
		]]
	}
}


BlendState BlendStateAlphaBlend
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE"
}
RasterizerState RasterizerState
{
	CullMode = "none"
	#FillMode = "wireframe"
}
DepthStencilState DepthStencilStateEnabled
{
	DepthEnable = no
	DepthWriteEnable = no
}

Effect strategic_objective_arrow
{
	VertexShader = "VS_strategic_objective_arrow"
	PixelShader = "PS_strategic_objective_arrow"

	BlendState = BlendStateAlphaBlend
	DepthStencilState = DepthStencilStateEnabled
}