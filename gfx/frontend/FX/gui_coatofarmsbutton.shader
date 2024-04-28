Includes = {
	"cw/pdxgui.fxh"
}

ConstantBuffer( 2 )
{
	float3 HighlightColor;
	float4 CoALeftTop_WidthHeight;
};

VertexStruct VS_OUTPUT_COA
{
	float4 Position		: PDX_POSITION;
	float2 UV			: TEXCOORD0;
	float2 RelativePos	: TEXCOORD1;
	float4 Color		: COLOR;
};

VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT_PDX_GUI"
		Output = "VS_OUTPUT_COA"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_COA Out;
				float2 PixelPos = WidgetLeftTop + Input.LeftTop_WidthHeight.xy + Input.Position * Input.LeftTop_WidthHeight.zw;
				Out.Position = PixelToScreenSpace( PixelPos );
				Out.UV.xy = Input.Position;
				Out.Color = Input.Color;
				Out.RelativePos = Input.Position;
				
				return Out;
			}
		]]
	}
}


PixelShader =
{
	TextureSampler Mask
	{
		Index = 0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	TextureSampler CoA
	{
		Index = 1
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	
	MainCode PixelShader
	{
		Input = "VS_OUTPUT_COA"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{	
				float mask = PdxTex2D( Mask, Input.RelativePos ).a;
				float2 UV = Input.UV.xy;
				float verticalOffset = 0.0f;
				UV.y = min( 1.0f, UV.y + verticalOffset );
				UV = CoALeftTop_WidthHeight.xy + UV.xy * CoALeftTop_WidthHeight.zw;
			
				float4 OutColor = PdxTex2D( CoA, UV.xy );
				OutColor *= mask;
				OutColor *= Input.Color;
				#ifndef NO_HIGHLIGHT
					OutColor.rgb += HighlightColor;
				#endif
				
				#ifdef DISABLED
					OutColor.rgb = DisableColor( OutColor.rgb );
				#endif
				
				return OutColor;
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

DepthStencilState DepthStencilState
{
	DepthEnable = no
}


Effect Up
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}

Effect Disabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" }
}


Effect NoHighlightUp
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "NO_HIGHLIGHT" }
}

Effect NoHighlightOver
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "NO_HIGHLIGHT" }
}

Effect NoHighlightDown
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "NO_HIGHLIGHT" }
}

Effect NoHighlightDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" "NO_HIGHLIGHT" }
}
