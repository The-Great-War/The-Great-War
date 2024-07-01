Includes = {
	"cw/pdxgui.fxh"
}

ConstantBuffer( 2 )
{
	float4 FrameSize_ProgressVec;
	float4 BgLeftTop_FgLeftTop;
	float4 BarColor;
};

VertexStruct VS_OUTPUT_PROGRESS_PIE
{
	float4 Position		: PDX_POSITION;
	float4 UV0UV1		: TEXCOORD0;
	float4 RelativePos_ProgressVec	: TEXCOORD1;
	float4 Color		: COLOR;
	float4 BarColor		: TEXCOORD2;
	float2 PixelFactor	: TEXCOORD3;
};

VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT_PDX_GUI"
		Output = "VS_OUTPUT_PROGRESS_PIE"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT_PROGRESS_PIE Out;
				float2 PixelPos = WidgetLeftTop + Input.LeftTop_WidthHeight.xy + Input.Position * Input.LeftTop_WidthHeight.zw;
				Out.Position = PixelToScreenSpace( PixelPos );
				Out.UV0UV1.xy = BgLeftTop_FgLeftTop.xy + Input.Position * FrameSize_ProgressVec.xy;
				Out.UV0UV1.zw = BgLeftTop_FgLeftTop.zw + Input.Position * FrameSize_ProgressVec.xy;
				Out.Color = Input.Color;
				Out.RelativePos_ProgressVec.xy = Input.Position;
				Out.RelativePos_ProgressVec.zw = FrameSize_ProgressVec.zw;
				// assuming the image is not stretched non-uniformly
				Out.PixelFactor = float2( 1.0 / Input.LeftTop_WidthHeight.z, Input.LeftTop_WidthHeight.z );
				Out.BarColor = BarColor;
				
				return Out;
			}
		]]
	}
}


PixelShader =
{
	TextureSampler Sprite
	{
		Index = 0
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}
	
	MainCode PixelShader
	{
		Input = "VS_OUTPUT_PROGRESS_PIE"
		Output = "PDX_COLOR"
		Code
		[[
			PDX_MAIN
			{	
				float4 BgColor = PdxTex2D( Sprite, Input.UV0UV1.xy ) * Input.Color;
				float4 FgColor = PdxTex2D( Sprite, Input.UV0UV1.zw ) * Input.BarColor;
				
				float2 DiffPos = Input.RelativePos_ProgressVec.xy - float2(0.5, 0.5);
				float vDot = dot( Input.RelativePos_ProgressVec.zw, DiffPos );
				
				// anti-alias at the border
				float fgFactor = 0.0f;
				if (vDot < 0.0 && vDot > -Input.PixelFactor.x) fgFactor = -vDot * Input.PixelFactor.y;
				else if (vDot < -Input.PixelFactor.x ) fgFactor = 1.0;
				
				// for progress < 50 % the left side is always a background, for > 50 % the right side is always a foreground
				// if sin is set to > 1.5, fill all with foreground
				float inVecSin = Input.RelativePos_ProgressVec.w;
				if ( inVecSin > 1.5 )
				{
					fgFactor = 1.0;
				}
				else if ( inVecSin >= 0.0 && DiffPos.x < 0.0 )
				{
					fgFactor = 0.0;
				}
				else if ( inVecSin < 0.0 && DiffPos.x > 0.0 )
				{
					fgFactor = 1.0;
				}
				
				float4 OutColor = lerp( BgColor, FgColor, fgFactor );
				
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


Effect PdxGuiProgressPie
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "PDX_GUI_CORNERED_SPRITE_SUPPORT" }
}

Effect PdxGuiProgressPieDisabled
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	
	Defines = { "DISABLED" "PDX_GUI_CORNERED_SPRITE_SUPPORT" }
}
