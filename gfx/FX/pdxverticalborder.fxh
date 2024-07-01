VertexShader =
{
	Code
	[[
		// Vertical Vertex Displacement
		#define VERTEX_DISPLACEMENT_MAGNITUDE 0.2f
		#define VERTEX_DISPLACEMENT_SPEED 1.0f

		#define UV01_SPEED 0.35
		#define UV02_SPEED 1.0
		#define UV03_SPEED 0.25
	]]
}

PixelShader =
{
	TextureSampler VerticalBorderLUT
	{
		Index = 9
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Clamp"
		SampleModeV = "Clamp"
		File = "gfx/map/borders/vertical_border_cloud_lut.dds"
		srgb = yes
	}

	Code
	[[
		// Settings for the vertical war border layers

		// Layer 1 - Vertical rays
		#define LAYER1_TOPALPHA_CONTRAST 0.9f

		// Layer 2 - Embers
		#define LAYER2_TOPALPHA_POSITION 1.05f
		#define LAYER2_TOPALPHA_CONTRAST 1.0f

		#define ANIMATION_SPEED 0.5f
		#define MOVEMENT_SPEED 2.0f
		#define MOVEMENT_DIRECTION float2( -0.1f, 1.0f )

		#define PARTICLE_SIZE 0.09f

		#define PARTICLE_SCALE ( float2( 0.5f, 2.0f ) )
		#define PARTICLE_SCALE_VAR ( float2( 0.25f, 0.2f ) )

		#define PARTICLE_BLOOM_SCALE ( float2( 1.5f, 1.5f ) )
		#define PARTICLE_BLOOM_SCALE_VAR ( float2( 0.3f, 0.1f ) )

		#define SPARK_COLOR float3( 1.0f, 0.2f, 0.05f ) * 1.0f
		#define BLOOM_COLOR float3( 1.0f, 0.2f, 0.05f ) * 1.0f

		#define SIZE_MOD 1.5f
		#define ALPHA_MOD 0.8f
		#define LAYERS_COUNT 8.0f

		#define UV_DIST_STRENGTH 0.12f
		#define UV_DIST_SCALE 3.0f

		#define COLOR_SMOOTHNESS 	5.0
		#define COLOR_MIN 			0.2
		#define COLOR_SATURATION	1.04
		#define COLOR_EMISSIVE		8.0

		#define UPPER_EDGE_HEIGHT  	0.4
		#define OPACITY 			1.0
		#define ALPHA_SHARPNESS 	0.7
		#define MAX_FLAME_LUT_COORD 0.95

		#define UPPER_EDGE_HEIGHT_LOW 	0.5
		#define OPACITY_LOW 			0.0
		#define ALPHA_SHARPNESS_LOW 	0.8
		#define MAX_LUT_COORD_LOW 0.3

		#define LOWER_EDGE_FALLOFF 0.6f
		#define LOWER_EDGE_MIN 0.08f
		#define LOWER_EDGE_MAX 0.2f

		// Escalation borders
		#define SMOKE_LOWER_EDGE_FALLOFF		0.6
		#define SMOKE_LOWER_EDGE_MIN 			0.08
		#define SMOKE_LOWER_EDGE_MAX 			0.2

		#define SMOKE_TEXTURE_PAN_SPEED_01 float2( 0.0, 0.1 )
		#define SMOKE_TEXTURE_PAN_SPEED_02 float2( 0.0, 0.1 )
		#define SMOKE_TEXTURE_UV_01 0.1
		#define SMOKE_TEXTURE_UV_02 0.25
		#define SMOKE_TEXTURE_DISTORTION 0.015

		#define SMOKE_TEXTURE_HEIGHT_MIN 0.2
		#define SMOKE_TEXTURE_HEIGHT_MAX 1.2

		#define SMOKE_NOISE_PAN_SPEED_01 float2( 0.1, 0.1 )
		#define SMOKE_NOISE_PAN_SPEED_02 float2( -0.1, 0.1 )
		#define SMOKE_NOISE_PAN_SPEED_03 float2( -0.2, 0.1 )

		#define SMOKE_NOISE_UV_01 0.5
		#define SMOKE_NOISE_UV_02 0.45
		#define SMOKE_NOISE_UV_03 0.25

		#define SMOKE_TINT float3( 0.45, 0.45, 0.55 )
	]]
}
