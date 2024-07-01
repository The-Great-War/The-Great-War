Includes = {
	"cw/heightmap.fxh"
	"jomini/jomini_water.fxh"
	"jomini/jomini_river.fxh"
	"pdxwater_game.fxh"
}

PixelShader =
{
	Code
	[[
		float4 CalcWaterLowSpec( VS_OUTPUT_WATER Input )
		{
			float Height = GetHeightMultisample( Input.WorldSpacePos.xz, 0.65 );
			float Depth = Input.WorldSpacePos.y - Height;

			float WaterFade = 1.0 - saturate( (_WaterFadeShoreMaskDepth - Depth) * _WaterFadeShoreMaskSharpness );
			float4 WaterColorAndSpec = PdxTex2D( WaterColorTexture, Input.UV01 );

			return float4( WaterColorAndSpec.xyz, WaterFade );
		}

		float4 CalcRiverLowSpec( in VS_OUTPUT_RIVER Input )
		{
			float Depth = CalcDepth( Input.UV );

			VS_OUTPUT_WATER WaterParams;
			WaterParams.Position = Input.Position;
			WaterParams.WorldSpacePos = Input.WorldSpacePos;
			WaterParams.UV01 = Input.WorldSpacePos.xz / MapSize;
			WaterParams.UV01.y = 1.0f - WaterParams.UV01.y;

			float4 Color = CalcWaterLowSpec( WaterParams );
			Color.a = saturate( Depth * 2.0f / _Depth ) * Input.Transparency * saturate( ( Input.DistanceToMain - 0.1f ) * 5.0f );
			return Color;
		}
	]]
}
