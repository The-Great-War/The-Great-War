Includes = {
	"cw/shadow.fxh"
	"cw/utility.fxh"
	"cw/camera.fxh"
	"jomini/jomini_lighting.fxh"
	"jomini/jomini_water.fxh"
	"jomini/jomini_river_bottom.fxh"
	"sharedconstants.fxh"
}

PixelShader =
{		
	
	MainCode PS_underwater
	{
		Input = "VS_OUTPUT_RIVER"
		Output = "PS_RIVER_BOTTOM_OUT"
		Code
		[[
			PDX_MAIN
			{				
				PS_RIVER_BOTTOM_OUT Out = CalcRiverBottomAdvanced( Input );

				return Out;	
			}
		]]
	}
}

Effect river_underwater
{
	VertexShader = "VertexShader"
	PixelShader = "PS_underwater"
}