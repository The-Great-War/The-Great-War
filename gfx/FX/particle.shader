Includes = {
	"sharedconstants.fxh"
	"cw/utility.fxh"
	"cw/camera.fxh"
}

PixelShader =
{
	TextureSampler DiffuseMap
	{
		Ref = PdxTexture0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
}


VertexStruct VS_INPUT_PARTICLE
{
	float2 vUV0			: TEXCOORD0;
	float4 vPosSize		: TEXCOORD1;
	float3 vRotation	: TEXCOORD2;
	uint4 vTile			: TEXCOORD3;
	float4 vColor		: COLOR;
};

VertexStruct VS_INPUT_PARTICLETRAIL
{
	float3 vPos			: POSITION;
	float2 vUV0			: TEXCOORD0;
	uint4 vTile			: TEXCOORD1;
	float4 vColor		: COLOR;	
};

VertexStruct VS_OUTPUT_PARTICLE
{
    float4 vPosition	: PDX_POSITION;
	float2 vUV0			: TEXCOORD0;
	float3 vPos			: TEXCOORD1;
	float4 vColor		: COLOR;
};


ConstantBuffer( 1 )
{
	float4x4 ProjectionMatrix_REMOVE;
};

ConstantBuffer( 2 )
{
	float2 Scale;
};

ConstantBuffer( 3 )
{
	float4x4 InstanceWorldMatrix;
	float4	HalfPixelWH_RowsCols;
	float	vLocalTime;
};


VertexShader =
{
	MainCode VertexParticle
	{				
		Input = "VS_INPUT_PARTICLE"
		Output = "VS_OUTPUT_PARTICLE"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PARTICLE Out;

				float2 offset = ( Input.vUV0 - 0.5f ) * Input.vPosSize.w * Scale.x;

				#ifdef NO_BILLBOARD
					float2 vSinCos;

					// Yaw
					sincos( Input.vRotation.x * ( 3.14159265359f / 180.0f ), vSinCos.x, vSinCos.y );
					float3x3 R0 = Create3x3( 
									float3( vSinCos.y, 0, -vSinCos.x ), 
									float3( 0, 1, 0 ), 
									float3( vSinCos.x, 0, vSinCos.y ) );


					// Pitch
					sincos( Input.vRotation.y * ( 3.14159265359f / 180.0f ), vSinCos.x, vSinCos.y );	
					float3x3 R1 = Create3x3( 
									float3( 1, 0, 0 ), 
									float3( 0, vSinCos.y, -vSinCos.x ), 
									float3( 0, vSinCos.x, vSinCos.y ) );

					// Roll
					sincos( Input.vRotation.z * ( 3.14159265359f / 180.0f ), vSinCos.x, vSinCos.y );
					float3x3 R2 = Create3x3( 
									float3( vSinCos.y, -vSinCos.x, 0 ), 
									float3( vSinCos.x, vSinCos.y, 0 ), 
									float3( 0, 0, 1 ) );

					float3x3 R = mul( R1, R2 );
					R = mul( R0, R );

					float3 vOffset = float3( offset.x, offset.y, 0 );
					vOffset = mul( R, vOffset );

					float3 vScaledPos = Input.vPosSize.xyz * Scale.y;
					float3 vNewPos = float3( vScaledPos.x + vOffset.x, vScaledPos.y + vOffset.y, vScaledPos.z + vOffset.z );
					float3 WorldPosition = mul( InstanceWorldMatrix, float4( vNewPos, 1.0 ) ).xyz;
				#else
					float2 vSinCos;
					sincos( Input.vRotation.z * ( 3.14159265359f / 180.0f ), vSinCos.x, vSinCos.y );
					offset = float2( 
					offset.x * vSinCos.y - offset.y * vSinCos.x, 
					offset.x * vSinCos.x + offset.y * vSinCos.y );

					float3 vScaledPos = Input.vPosSize.xyz * Scale.y;
					float3 WorldPosition = mul( InstanceWorldMatrix, float4( vScaledPos, 1.0 ) ).xyz;
				#endif

				Out.vPos = WorldPosition;
				Out.vPosition = FixProjectionAndMul( ViewProjectionMatrix, float4( WorldPosition, 1.0 ) );		

				#ifndef NO_BILLBOARD
					Out.vPosition.xy += offset * float2( ProjectionMatrix_REMOVE[0][0], ProjectionMatrix_REMOVE[1][1] );
				#endif
			
				Out.vColor = ToLinear(Input.vColor);
				
				float2 tmpUV = float2( Input.vUV0.x, 1.0f - Input.vUV0.y );
				Out.vUV0 = HalfPixelWH_RowsCols.xy + ( Input.vTile.xy + tmpUV ) / HalfPixelWH_RowsCols.zw - HalfPixelWH_RowsCols.xy * 2.0f * tmpUV;
				return Out;
			}
		]]
	}

	MainCode VertexParticleTrail
	{
		Input = "VS_INPUT_PARTICLETRAIL"
		Output = "VS_OUTPUT_PARTICLE"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PARTICLE Out;

				float3 WorldPosition = mul( InstanceWorldMatrix, float4(  Input.vPos.xyz, 1.0 ) ).xyz;
				Out.vPos = WorldPosition;
				Out.vPosition = FixProjectionAndMul( ViewProjectionMatrix, float4( WorldPosition, 1.0 ) );
				
				Out.vColor = ToLinear(Input.vColor);

				Out.vUV0 = HalfPixelWH_RowsCols.xy + ( Input.vTile.xy + Input.vUV0 ) / HalfPixelWH_RowsCols.zw - HalfPixelWH_RowsCols.xy * 2.0f * Input.vUV0;
				return Out;
			}
		]]
	}
}

PixelShader =
{
	MainCode PixelParticle
	{
		Input = "VS_OUTPUT_PARTICLE"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{
				float4 vColor = PdxTex2D( DiffuseMap, Input.vUV0 ) * Input.vColor;				
				return vColor;
			}
		]]
	}
}

DepthStencilState DepthStencilState
{
	DepthEnable = yes
	DepthWriteEnable = no
}
DepthStencilState DepthStencilNoZ
{
	DepthEnable = no
	DepthWriteEnable = no
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE"
}

BlendState BlendStateAdditive
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "ONE"
	WriteMask = "RED|GREEN|BLUE|ALPHA"
}

BlendState BlendStatePreAlphaBlend
{
	BlendEnable = yes
	SourceBlend = "ONE"
	DestBlend = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE"
}


RasterizerState RasterizerState
{
	FillMode = "solid"
	CullMode = "back"
	FrontCCW = no
}

RasterizerState RasterizerStateNoCulling
{
	FillMode = "solid"
	CullMode = "none"
	FrontCCW = no
}

Effect ParticleAlphaBlend
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelParticle"
}

Effect ParticlePreAlphaBlend
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelParticle"
	BlendState = "BlendStatePreAlphaBlend"
}

Effect ParticleAdditive
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelParticle"
	BlendState = "BlendStateAdditive"
}

Effect ParticleAdditiveNoDepth
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelParticle"
	BlendState = "BlendStateAdditive"
	DepthStencilState = "DepthStencilNoZ"
}

Effect ParticleAlphaBlendNoBillboard
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelParticle"
	RasterizerState = "RasterizerStateNoCulling"
	Defines = { "NO_BILLBOARD" }
}

Effect ParticlePreAlphaBlendNoBillboard
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelParticle"
	BlendState = "BlendStatePreAlphaBlend"
	RasterizerState = "RasterizerStateNoCulling"
	Defines = { "NO_BILLBOARD" }
}

Effect ParticleAdditiveNoBillboard
{
	VertexShader = "VertexParticle"
	PixelShader = "PixelParticle"
	BlendState = "BlendStateAdditive"
	RasterizerState = "RasterizerStateNoCulling"
	Defines = { "NO_BILLBOARD" }
}

Effect ParticleAlphaBlendTrail
{
	VertexShader = "VertexParticleTrail"
	PixelShader = "PixelParticle"
	BlendState = "BlendStateAdditive"
	RasterizerState = "RasterizerStateNoCulling"
	Defines = { "IS_TRAIL" }
}

Effect ParticlePreAlphaBlendTrail
{
	VertexShader = "VertexParticleTrail"
	PixelShader = "PixelParticle"
	BlendState = "BlendStatePreAlphaBlend"
	RasterizerState = "RasterizerStateNoCulling"
	Defines = { "IS_TRAIL" }
}

Effect ParticleAdditiveTrail
{
	VertexShader = "VertexParticleTrail"
	PixelShader = "PixelParticle"
	BlendState = "BlendStateAdditive"
	RasterizerState = "RasterizerStateNoCulling"
	Defines = { "IS_TRAIL" }
}

Effect ParticleAlphaBlendTrailNoBillboard
{
	VertexShader = "VertexParticleTrail"
	PixelShader = "PixelParticle"
	BlendState = "BlendStateAdditive"
	RasterizerState = "RasterizerStateNoCulling"
	Defines = { "IS_TRAIL" "NO_BILLBOARD" }
}

Effect ParticlePreAlphaBlendTrailNoBillboard
{
	VertexShader = "VertexParticleTrail"
	PixelShader = "PixelParticle"
	BlendState = "BlendStatePreAlphaBlend"
	RasterizerState = "RasterizerStateNoCulling"
	Defines = { "IS_TRAIL" "NO_BILLBOARD" }
}

Effect ParticleAdditiveTrailNoBillboard
{
	VertexShader = "VertexParticleTrail"
	PixelShader = "PixelParticle"
	BlendState = "BlendStateAdditive"
	RasterizerState = "RasterizerStateNoCulling"
	Defines = { "IS_TRAIL" "NO_BILLBOARD" }
}