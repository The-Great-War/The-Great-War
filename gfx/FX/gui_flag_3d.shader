Includes = {
	"jomini/jomini_lighting.fxh"
	"cw/pdxmesh.fxh"
	"cw/utility.fxh"
	"cw/lighting.fxh"
	"cw/lighting_util.fxh"
	"sharedconstants.fxh"
}

PixelShader =
{
	TextureSampler DiffuseMap
	{
		Index = 0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler SpecularMap
	{
		Index = 1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler NormalMap
	{
		Index = 2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler FlagTexture
	{
		Ref = PdxMeshCustomTexture0
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

ConstantBuffer( GuiFlagConstants )
{
	float SmallWaveScale;
	float WaveScale;
	float AnimationSpeed;
}


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
		void CalculateSineAnimation( float2 UV, inout float3 Position, inout float3 Normal, inout float4 Tangent )
		{
			float AnimSeed = UV.x;

			float Time = GlobalTime * AnimationSpeed;

			float SmallWaveV = Time - AnimSeed * SmallWaveScale;
			float SmallWaveD = -( AnimSeed * SmallWaveScale );
			float SmallWave = sin( SmallWaveV );
			float CombinedWave = SmallWave;

			// Wave
			float3 AnimationDir = float3( 0, 0.08, -1 );
			float Wave = WaveScale * smoothstep( 0.0, 0.12, AnimSeed ) * CombinedWave;
			float Derivative = ( WaveScale * 1.0f) * AnimSeed * -( SmallWave + cos( SmallWaveV ) * SmallWaveD );

			// Vertex position
			Position += AnimationDir * Wave;

			// Normals
			float2 WaveTangent = normalize( float2( 1.0f, Derivative ) );
			float3 WaveNormal = normalize( float3( WaveTangent.y, 0.0f, -WaveTangent.x ));

			float WaveNormalStrength = 1.0f;

			Normal = normalize( lerp( Normal, WaveNormal, 0.65f ) ); // Wave normal strength
		}
	]]

	MainCode VS_standard
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT Out = ConvertOutput( PdxMeshVertexShaderStandard( Input ) );
				Out.InstanceIndex = Input.InstanceIndices.y;
				return Out;
			}
		]]
	}
	MainCode VS_animated
	{
		Input = "VS_INPUT_PDXMESHSTANDARD"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				float2 AnimUV = saturate( Input.Position.xy / float2( 9.0f, 6.0f ) + vec2( 0.5f ) );
				CalculateSineAnimation( AnimUV, Input.Position, Input.Normal, Input.Tangent );
				VS_OUTPUT Out = ConvertOutput( PdxMeshVertexShaderStandard( Input ) );
				Out.InstanceIndex = Input.InstanceIndices.y;
				return Out;
			}
		]]
	}
}

PixelShader =
{
	MainCode PS_standard
	{
		Input = "VS_OUTPUT"
		Output = "PDX_COLOR"
		Code
		[[
			float4 GetUserColor( uint InstanceIndex )
			{
				return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ];
			}
			float4 GetOffsetAndScale( uint InstanceIndex )
			{
				return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ];
			}
			float4 GetFadeValues( uint InstanceIndex )
			{
				return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 2 ];
			}
			PDX_MAIN
			{
				float4 Diffuse = PdxTex2D( DiffuseMap, Input.UV0 );
				clip( Diffuse.a - 0.01f );

				float4 Properties = PdxTex2D( SpecularMap, Input.UV0 );
				float3 NormalSample = UnpackRRxGNormal( PdxTex2D( NormalMap, Input.UV0 ) );

				#ifdef FLAG
					float4 OffsetAndScale = GetOffsetAndScale( Input.InstanceIndex );
					float2 UV1 = OffsetAndScale.xy + ( Input.UV1 * OffsetAndScale.zw );
					float3 FlagColor = ToLinear(PdxTex2D( FlagTexture, UV1 ).rgb);

					Diffuse.rgb *= FlagColor;
				#endif

				float3 InNormal = normalize( Input.Normal );
				float3x3 TBN = Create3x3( normalize( Input.Tangent ), normalize( Input.Bitangent ), InNormal );

				float3 Normal = normalize( mul( NormalSample, TBN ) );

				SMaterialProperties MaterialProps = GetMaterialProperties( Diffuse.rgb, Normal, Properties.a, Properties.g, Properties.b );
				SLightingProperties LightingProps = GetSunLightingProperties( Input.WorldSpacePos, 1.0f );

				float4 FinalColor = Diffuse;
				FinalColor.rgb = CalculateSunLighting( MaterialProps, LightingProps, EnvironmentMap );

				// Color adjustments
				float3 HSV_ = RGBtoHSV( FinalColor.rgb );
				HSV_.x += 0.0f;		// Hue
				HSV_.y *= 0.88f; 	// Saturation
				HSV_.z *= 1.00f;	// Value
				FinalColor.rgb = HSVtoRGB( HSV_ );
				FinalColor.rgb = saturate( FinalColor.rgb * float3( 1.03f, 0.77f, 0.74f ) );
				FinalColor.rgb = ToGamma( FinalColor.rgb );
				FinalColor.rgb = saturate( FinalColor.rgb );

				// Gradient Fade
				float4 FadeValues = GetFadeValues( Input.InstanceIndex );
				if ( length( FadeValues ) > 0.0 )
				{
					float2 Vector = FadeValues.xy - FadeValues.zw;
					float Fade = dot( Input.UV0 - FadeValues.zw, Vector) / dot( Vector, Vector );
					Fade = smoothstep( 0.0, 1.0, clamp( Fade, 0.0, 1.0 ) );
					FinalColor.a *= lerp( 0.0, 1.0, Fade );
				}

				return FinalColor;
			}
		]]
	}
}


BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	SourceAlpha = "ONE"
	DestAlpha = "INV_SRC_ALPHA"
}

Effect gui_flag_textured
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
	Defines = { "FLAG" }
}
Effect gui_flag_untextured
{
	VertexShader = "VS_standard"
	PixelShader = "PS_standard"
}

Effect gui_flag_textured_vertex_anim
{
	VertexShader = "VS_animated"
	PixelShader = "PS_standard"
	Defines = { "FLAG" }
}
Effect gui_flag_untextured_vertex_anim
{
	VertexShader = "VS_animated"
	PixelShader = "PS_standard"
}