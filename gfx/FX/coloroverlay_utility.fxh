PixelShader = {

	TextureSampler FlatmapNoiseMap
	{
		Index = 7
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/flatmap_noise.dds"
		srgb = no
	}

	TextureSampler LandMaskMap
	{
		Index = 9
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/land_mask.dds"
		srgb = yes
	}

	#// Highlight in Red
	#// Occupatioon in Green
	TextureSampler HighlightGradient
	{
		Ref = HighlightGradient
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}

	TextureSampler ImpassableTerrainTexture
	{
		Ref = ImpassableTerrain
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}

	TextureSampler MapPaintingTextures
	{
		Ref = MapPaintingTexturesRef
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		type = "2darray"
	}
	TextureSampler FlatmapOverlayTexture
	{
		Ref = FlatmapOverlay
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Clamp"
	}

	TextureSampler CountryColors
	{
		Ref = CountryColors
		MagFilter = "Point"
		MinFilter = "Point"
		MipFilter = "Point"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
	}

	# Coa Data
	TextureSampler CoaAtlas
	{
		Ref = CoaAtlasTexture
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler PowerBlocAtlas
	{
		Ref = PowerBlocAtlasTexture
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	BufferTexture ProvinceCountryIdBuffer
	{
		Ref = ProvinceCountryId
		type = int
	}
	BufferTexture ProvinceControllerIdBuffer
	{
		Ref = ProvinceControllerId
		type = float2
	}
	BufferTexture CountryCoaUvBuffer
	{
		Ref = CountryFlagUvs
		type = float4
	}

	Code
	[[
		int SampleCountryIndex( float2 MapCoords )
		{
			float2 ColorIndex = PdxTex2D( ProvinceColorIndirectionTexture, MapCoords ).rg;
			int Index = ColorIndex.x * 255.0 + ColorIndex.y * 255.0 * 256.0;
			return PdxReadBuffer( ProvinceCountryIdBuffer, Index );
		}

		float2 SampleControllerIndex( float2 MapCoords )
		{
			float2 ColorIndex = PdxTex2D( ProvinceColorIndirectionTexture, MapCoords ).rg;
			int Index = ColorIndex.x * 255.0 + ColorIndex.y * 255.0 * 256.0;
			return PdxReadBuffer2( ProvinceControllerIdBuffer, Index );
		}
	]]
}