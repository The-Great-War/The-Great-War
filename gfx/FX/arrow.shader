Includes = {
	"cw/camera.fxh"
	"sharedconstants.fxh"
	"standardfuncsgfx.fxh"
	"coloroverlay.fxh"
}

VertexStruct VS_INPUT
{
	float3 vPosition  : POSITION;
	float2 vTexCoord  : TEXCOORD0;
};

VertexStruct VS_OUTPUT
{
	float4 vPosition : PDX_POSITION;
	float2 vTexCoord : TEXCOORD0;
	float3 vPos		 : TEXCOORD1;
};

ConstantBuffer( 0 )
{
	float AnimationLength;
	float MoveLength;
	float ClipLength;
	float TotalLength;
	float Width;
};

VertexShader =
{
	MainCode VertexShader
	{
		Input = "VS_INPUT"
		Output = "VS_OUTPUT"
		Code
		[[
			PDX_MAIN
			{
				VS_OUTPUT Out;
				float4 pos = float4( Input.vPosition, 1.0f );
			#ifdef FLAT_MAP
				pos.y = lerp( pos.y, _FlatmapHeight, _FlatmapLerp );
			#endif
				pos.y += 0.15f;

				Out.vPos = pos.xyz;
				Out.vPosition  = FixProjectionAndMul( ViewProjectionMatrix, pos );
				Out.vTexCoord = Input.vTexCoord;

				return Out;
			}
		]]
	}
}


PixelShader =
{
	TextureSampler DiffuseTexture
	{
		Index = 0
		MipFilter = "Linear"
		MinFilter = "Linear"
		MagFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}

	MainCode PixelShader
	{
		Input = VS_OUTPUT
		Output = PDX_COLOR

		Code
		[[
			PDX_MAIN
			{
				// Map Uvs
				float2 ProvinceCoords = Input.vPos.xz / _ProvinceMapSize;
				float2 MapCoords = ( Input.vPos.xz * _WorldSpaceToTerrain0To1 );
				MapCoords.x *= 2.0;

				// Unit position
				float Passed = Input.vTexCoord.y < MoveLength ? 1.0f : 0.0f;

				// Inital Uv tiling
				float Tiling = 10.0 * Width;
				float NumTiles = floor( TotalLength / Tiling );
				float Offset = ( TotalLength - ( Tiling * NumTiles ) ) / Tiling;
				float2 Uv = Input.vTexCoord.xy;
				Uv.y /= Tiling;
				Uv.y = Uv.y + 1.0 - Offset;
				Uv.x *= 0.5;

				float2 texDdx = ddx( Uv );
				float2 texDdy = ddy( Uv );

				// Find and repeat Uv segments along the full spline, with a different end point
				float ArrowEnd = lerp( 0.5, 0.0, _FlatmapLerp );
				float Tile = Uv.y;
				Uv.y = mod( Uv.y, 1.0 );
				if( Tile >= NumTiles )
				{
					Uv.y += ArrowEnd;
				}
				else if( frac( Tile ) > 0.5 )
				{
					Uv.y = 0.5 - Uv.y;
				}
				Uv.y = 1.0 - Uv.y;

				// Settings, Todo: Move these to a file
				float3 BaseColorPicker = float3( 0.05, 0.15, 0.5 ) * 0.55;
				float3 FillColorPicker = float3( 0.11, 0.25, 0.9 );
				float3 OutlineColorPicker = BaseColorPicker * 1.7;
				float Opacity = 0.65;
				int ArrowSpacing = 4.0;
				float ArrowSpeed = 1.0;
				float FlatmapUvScaling = 1.0;

				// Finding water vs land
				float4 AlternateColor = BilinearColorSampleAtOffset( ProvinceCoords, IndirectionMapSize, InvIndirectionMapSize, ProvinceColorIndirectionTexture, ProvinceColorTexture, AlternateProvinceColorsOffset );
				AlternateColor.rg = vec2( 0.0f ); // Zero out unused channels to avoid issues
				float4 LakeColor = float4( 0.0f, 0.0f, 0.0f, 1.0f ); // Needs to match color in mappaintingmanager.cpp
				float4 SeaColor = float4( 0.0f, 0.0f, 1.0f, 0.0f );	// Needs to match color in mappaintingmanager.cpp
				float4 LakeDiff = LakeColor - AlternateColor;
				float4 SeaDiff = SeaColor - AlternateColor;
				float WaterLerp = 1.0 - ( dot( LakeDiff, LakeDiff ) * dot( SeaDiff, SeaDiff ) );

				// Flatmap specific settings
				#ifdef FLAT_MAP
					Opacity = 1.0;
					ArrowSpacing = 3.0;
					FlatmapUvScaling = 0.2;

					BaseColorPicker *= 1.35;
				#endif

				BaseColorPicker = lerp( float3( 0.6, 0.5, 0.5 ) * 0.35, BaseColorPicker, WaterLerp );
				FillColorPicker = lerp( float3( 0.6, 0.5, 0.5 ) * 0.85, FillColorPicker, WaterLerp );
				OutlineColorPicker = lerp( float3( 0.6, 0.5, 0.5 ) * 0.85, OutlineColorPicker, WaterLerp );

				// Animated Caustics
				float3x3 BaseMatrix = Create3x3( -2.0, -1.0, 2.0, 3.0, -2.0, 1.0, 1.0, 2.0, 2.0 );
				float2 CausticUv = MapCoords * 220.0;
				CausticUv = lerp( CausticUv, CausticUv * 0.35, _FlatmapLerp );
				float Speed = 0.05;
				float3 a = mul( float3( CausticUv.x, CausticUv.y, GlobalTime * Speed ), BaseMatrix );
				float3 b = mul( a, BaseMatrix ) * 0.4;
				float3 c = mul( b, BaseMatrix ) * 0.3;
				float CausticsNoise = float( pow( min( min( length( 0.5 - frac( a ) ), length( 0.5 - frac( b ) ) ), length( 0.5 - frac( c ) ) ), 6.0 ) * 9.0 );
				float3 CausticsColor = float3( 0.05, 0.15, 0.9 ) * 0.75 * CausticsNoise;

				// Arrow Base
				float FillMask = PdxTex2DGrad( DiffuseTexture, Uv, texDdx, texDdy ).a;
				float OutlineMask = PdxTex2DGrad( DiffuseTexture, Uv, texDdx, texDdy ).g;

				// Inner Arrow
				float UvLength = Input.vTexCoord.y * 0.25 * FlatmapUvScaling;
				UvLength -= GlobalTime * ArrowSpeed;
				float2 InnerArrowUv = float2( Input.vTexCoord.x, UvLength );
				InnerArrowUv = 1.0 - mod( abs( InnerArrowUv ), 1.0 );

				// Fix for when the Uvs pan into the negative
				if ( UvLength < 0.0 )
				{
					InnerArrowUv.y = 1.0 - InnerArrowUv.y;
					UvLength -= 1.0;
				}

				// Inner Arrow Segment
				float Segment = step( mod( abs( UvLength ), ArrowSpacing ), 1.0 );

				// Inner Arrow Mask
				float InnerArrowMask = PdxTex2DGrad( DiffuseTexture, InnerArrowUv, texDdx, texDdy ).r;
				InnerArrowMask = ( InnerArrowMask * FillMask );

				// Colors land vs sea
				BaseColorPicker = lerp( BaseColorPicker, BaseColorPicker + CausticsColor * ( 1.0 - Passed ), WaterLerp );
				FillColorPicker = lerp( FillColorPicker, FillColorPicker, WaterLerp );
				OutlineColorPicker = lerp( OutlineColorPicker * 0.1, OutlineColorPicker, WaterLerp );
				float3 InnerArrowColor = InnerArrowMask * BaseColorPicker * 2.0;
				InnerArrowColor = lerp( InnerArrowColor, InnerArrowColor + CausticsColor * 3.0, WaterLerp );

				// Colors when passed
				#ifndef FLAT_MAP
					float3 FillColor = lerp( BaseColorPicker, FillColorPicker, Passed );
					float3 OutlineColor = OutlineColorPicker;
					InnerArrowColor = lerp( InnerArrowColor, InnerArrowColor * 0.5, Passed );
				#else
					float3 FillColor = lerp( BaseColorPicker, FillColorPicker, Passed );
					float3 OutlineColor = OutlineColorPicker;
					InnerArrowColor = lerp( InnerArrowColor, InnerArrowColor * 0.5, Passed );
				#endif

				// Compounded
				float3 OutColor = lerp( FillColor, OutlineColor, OutlineMask );
				OutColor = lerp( OutColor, InnerArrowColor, Segment * saturate( InnerArrowMask - OutlineMask ) );
				Opacity = FillMask * Opacity;

				// Alpha
				float vFadeLength = ClipLength + 2.0f;
				float FadeAlpha = Input.vTexCoord.y - vFadeLength;
				FadeAlpha = saturate( FadeAlpha * saturate( 1.0f - ( FadeAlpha / -vFadeLength ) ) );
				Opacity *= FadeAlpha;

				// Close fade
				Opacity = FadeCloseAlpha( Opacity );

				return float4( OutColor, Opacity );
			}
		]]
	}
}


BlendState ArrowBlendState
{
 	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}

RasterizerState RasterizerState
{
 	DepthBias = 0
	#fillmode = wireframe
}

DepthStencilState DepthStencilState
{
	DepthEnable = yes
	DepthWriteEnable = no
}

Effect ArrowEffect
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = "ArrowBlendState"
}

Effect ArrowEffectFlatMap
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
	BlendState = "ArrowBlendState"

	Defines = { "FLAT_MAP" }
}