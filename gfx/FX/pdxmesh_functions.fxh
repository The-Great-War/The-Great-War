Includes = {
	"cw/pdxmesh.fxh"
	"cw/terrain.fxh"
	"cw/camera.fxh"
	"cw/utility.fxh"
	"jomini/jomini_water.fxh"
	"sharedconstants.fxh"
}

VertexShader =
{
	TextureSampler WindMapTree
	{
		Ref = WindMapTree
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler FlowMapTexture
	{
		Ref = JominiWaterTexture2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
}

PixelShader =
{
	TextureSampler SolLowTexture
	{
		Ref = SolLowTexture
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
}

struct SStandardMeshUserData
{
	float _CountryIndex;
	float _RandomValue;
	float _PowerBlocIndex;
	float _Padding03;
};

struct SBuildingMeshUserdata
{
	float4 _LightColor;
	float _CountryIndex;
	float _RandomValue;
	float _SolValue;
	float _ShouldLightActivate;

	float _HasCompanyTexture;
	float _PowerBlocIndex;
};

struct SRevolutionMeshUserdata
{
	float _IgColorIndex;
	float _Padding01;
	float _Padding02;
	float _Padding03;
};

struct WaveAnimationSettings
{
	float LargeWaveFrequency;		// Higher values simulates higher wind speeds / more turbulence
	float SmallWaveFrequency;		// Higher values simulates higher wind speeds / more turbulence
	float WaveLenghtPow;			// Higher values gives higher frequency at the end of the flag
	float WaveLengthInvScale;		// Higher values gives higher frequency overall
	float WaveScale;				// Higher values gives a stretchier flag
	float AnimationSpeed;			// Speed
};

Code
[[
	float GetSeed()
	{
		#if defined( HIGH_QUALITY_SHADERS )
			#if defined( SEED_01 )
				return 1;
			#elif defined( SEED_02 )
				return 2;
			#elif defined( SEED_03 )
				return 3;
			#elif defined( SEED_04 )
				return 4;
			#elif defined( SEED_05 )
				return 5;
			#elif defined( SEED_06 )
				return 6;
			#elif defined( SEED_07 )
				return 7;
			#elif defined( SEED_08 )
				return 8;
			#elif defined( SEED_09 )
				return 9;
			#elif defined( SEED_10 )
				return 10;
			#elif defined( SEED_11 )
				return 11;
			#elif defined( SEED_12 )
				return 12;
			#elif defined( SEED_13 )
				return 13;
			#elif defined( SEED_14 )
				return 14;
			#elif defined( SEED_15 )
				return 15;
			#elif defined( SEED_16 )
				return 16;
			#elif defined( SEED_17 )
				return 17;
			#elif defined( SEED_18 )
				return 18;
			#elif defined( SEED_19 )
				return 19;
			#elif defined( SEED_20 )
				return 20;
			#endif
		#endif

		return 546546;
	}
	uint GetUserDataUint( uint InstanceIndex )
	{
		return uint( Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].x );
	}
	float GetUserDataFloat( uint InstanceIndex )
	{
		return uint( Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].x );
	}
	int GetUserDataCountryIndex( uint InstanceIndex )
	{
		return int( Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].x );
	}
	float4 GetUserDataBuildingLightColor( uint InstanceIndex )
	{
		return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ];
	}
	float GetUserDataPrettyValue( uint InstanceIndex )
	{
		return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].x;
	}
	float GetUserDataRandomValueCity( uint InstanceIndex )
	{
		return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].y;
	}
	float GetUserDataShouldLightActivate( uint InstanceIndex )
	{
		return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].z;
	}

	SStandardMeshUserData GetStandardMeshUserData( uint InstanceIndex )
	{
		SStandardMeshUserData UserData;
		UserData._CountryIndex = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].x;
		UserData._RandomValue = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].y;
		UserData._PowerBlocIndex = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].z;
		return UserData;
	}

	SBuildingMeshUserdata GetBuildingMeshUserData( uint InstanceIndex )
	{
		SBuildingMeshUserdata UserData;
		UserData._LightColor = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ];

		UserData._CountryIndex = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].x;
		UserData._RandomValue = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].y;
		UserData._SolValue = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].z;
		UserData._ShouldLightActivate = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].w;

		UserData._HasCompanyTexture = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 2 ].x;
		UserData._PowerBlocIndex = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 2 ].y;

		return UserData;
	}
]]

VertexShader =
{
	Code
	[[
		WaveAnimationSettings GetWaveAnimationSettingsDefault()
		{
			WaveAnimationSettings WaveAnimSettings;
			WaveAnimSettings.LargeWaveFrequency = 3.14f;
			WaveAnimSettings.SmallWaveFrequency = 9.0f;
			WaveAnimSettings.WaveLenghtPow = 1.0f;
			WaveAnimSettings.WaveLengthInvScale = 7.0f;
			WaveAnimSettings.WaveScale = 0.2f;
			WaveAnimSettings.AnimationSpeed = 0.5f;

			return WaveAnimSettings;
		}
		WaveAnimationSettings GetWaveAnimationSettingsBuilding()
		{
			WaveAnimationSettings WaveAnimSettings;
			WaveAnimSettings.LargeWaveFrequency = 2.0f;
			WaveAnimSettings.SmallWaveFrequency = 7.0f;
			WaveAnimSettings.WaveLenghtPow = 1.0f;
			WaveAnimSettings.WaveLengthInvScale = 5.0f;
			WaveAnimSettings.WaveScale = 0.08f;
			WaveAnimSettings.AnimationSpeed = 0.5f;

			return WaveAnimSettings;
		}

		void CalculateSineAnimation( float2 UV, inout float3 Position, inout float3 Normal, inout float4 Tangent, float Seed )
		{
			#if defined( FLAGWAVE_SETTINGS_BUILDING )
			WaveAnimationSettings AnimSettings = GetWaveAnimationSettingsBuilding();
			#else
				WaveAnimationSettings AnimSettings = GetWaveAnimationSettingsDefault();
			#endif

			float AnimSeed = UV.x;
			float RandomOffset = CalcRandom( Seed + GetSeed() );
			float Time = ( GlobalTime + RandomOffset ) * AnimSettings.AnimationSpeed;

			float LargeWave = sin( Time * AnimSettings.LargeWaveFrequency );
			float SmallWaveV = Time * AnimSettings.SmallWaveFrequency - pow( AnimSeed, AnimSettings.WaveLenghtPow ) * AnimSettings.WaveLengthInvScale;
			float SmallWaveD = -( AnimSettings.WaveLenghtPow * pow( AnimSeed, AnimSettings.WaveLenghtPow ) * AnimSettings.WaveLengthInvScale );
			float SmallWave = sin( SmallWaveV );
			float CombinedWave = SmallWave + LargeWave;

			float Wave = AnimSettings.WaveScale * AnimSeed * CombinedWave;
			float Derivative = AnimSettings.WaveScale * ( LargeWave + SmallWave + cos( SmallWaveV ) * SmallWaveD );
			float3 AnimationDir = cross( Tangent.xyz, float3( 0.0, 1.0, 0.0 ) );

			Position += AnimationDir * Wave;

			float2 WaveTangent = normalize( float2( 1.0f, Derivative ) );
			float3 WaveNormal = normalize( float3( WaveTangent.y, 0.0f, -WaveTangent.x ));
			Normal = normalize( WaveNormal ); // wave normal strength
		}

		float3 WindTransform( float3 Position, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( Position, 1.0f ) ).xyz;
			float2 MapCoords = float2( WorldSpacePos.x / MapSize.x, 1.0 - WorldSpacePos.z / MapSize.y );

			float3 FlowMap = PdxTex2DLod0( FlowMapTexture, MapCoords ).rgb;
			float3 FlowDir = FlowMap.xyz * 2.0 - 1.0;
			FlowDir = FlowDir / ( length( FlowDir ) + 0.000001 ); // Intel did not like normalize()

			float WindMap = PdxTex2DLod0( WindMapTree, MapCoords ).r;

			float WorldX = GetMatrixData( WorldMatrix, 0, 3 );
			float WorldY = GetMatrixData( WorldMatrix, 2, 3 );
			float Noise = CalcNoise( GlobalTime * TreeSwayLoopSpeed + TreeSwayWindStrengthSpatialModifier * float2( WorldX, WorldY ) );
			float WindSpeed = Noise * Noise;
			float Phase = GlobalTime * TreeSwaySpeed + TreeSwayWindClusterSizeModifier * ( WorldX + WorldY );
			float3 Offset = normalize( float3( FlowDir.x, 0.0f, FlowDir.z ) );
			Offset = mul( Offset, CastTo3x3( WorldMatrix ) );
			float HeightFactor = saturate( Position.y * TreeHeightImpactOnSway );
			HeightFactor *= HeightFactor;

			float wave = sin( Phase ) + 0.5f;
			Position += TreeSwayScale * WindMap * HeightFactor * wave * Offset * WindSpeed;

			return Position;
		}

		float3 WindTransformBush( float3 Position, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( Position, 1.0f ) ).xyz;
			float2 MapCoords = float2( WorldSpacePos.x / MapSize.x, 1.0 - WorldSpacePos.z / MapSize.y );

			float3 FlowMap = PdxTex2DLod0( FlowMapTexture, MapCoords ).rgb;
			float3 FlowDir = FlowMap.xyz * 2.0 - 1.0;
			FlowDir = FlowDir / ( length( FlowDir ) + 0.000001 ); // Intel did not like normalize()

			float WindMap = PdxTex2DLod0( WindMapTree, MapCoords ).r;

			float WorldX = GetMatrixData( WorldMatrix, 0, 3 );
			float WorldY = GetMatrixData( WorldMatrix, 2, 3 );
			float Noise = CalcNoise( GlobalTime * TreeSwayLoopSpeed + TreeSwayWindStrengthSpatialModifier * float2( WorldX, WorldY ) );
			float WindSpeed = Noise * Noise;
			float Phase = GlobalTime * TreeSwaySpeed + TreeSwayWindClusterSizeModifier * ( WorldX + WorldY );
			float3 Offset = normalize( float3( FlowDir.x, 0.0f, FlowDir.z ) );
			Offset = mul( Offset, CastTo3x3( WorldMatrix ) );
			float HeightFactor = saturate( Position.y * TreeHeightImpactOnSway * BUSH_TREE_HEIGHT_IMPACT );
			HeightFactor *= HeightFactor;

			float wave = sin( Phase ) + 0.5f;
			Position += TreeSwayScale * BUSH_TREE_SWAY_SCALE * WindMap * HeightFactor * wave * Offset * WindSpeed;

			return Position;
		}

		float3 WindTransformMedium( float3 Position, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( Position, 1.0f ) ).xyz;
			float2 MapCoords = float2( WorldSpacePos.x / MapSize.x, 1.0 - WorldSpacePos.z / MapSize.y );

			float3 FlowMap = PdxTex2DLod0( FlowMapTexture, MapCoords ).rgb;
			float3 FlowDir = FlowMap.xyz * 2.0 - 1.0;
			FlowDir = FlowDir / ( length( FlowDir ) + 0.000001 ); // Intel did not like normalize()

			float WindMap = PdxTex2DLod0( WindMapTree, MapCoords ).r;

			float WorldX = GetMatrixData( WorldMatrix, 0, 3 );
			float WorldY = GetMatrixData( WorldMatrix, 2, 3 );
			float Noise = CalcNoise( GlobalTime * TreeSwayLoopSpeed + TreeSwayWindStrengthSpatialModifier * float2( WorldX, WorldY ) );
			float WindSpeed = Noise * Noise;
			float Phase = GlobalTime * TreeSwaySpeed * MEDIUM_TREE_SWAY_SPEED + TreeSwayWindClusterSizeModifier * ( WorldX + WorldY );
			float3 Offset = normalize( float3( FlowDir.x, 0.0f, FlowDir.z ) );
			Offset = mul( Offset, CastTo3x3( WorldMatrix ) );
			float HeightFactor = saturate( Position.y * TreeHeightImpactOnSway * MEDIUM_TREE_HEIGHT_IMPACT );
			HeightFactor *= HeightFactor;

			float wave = sin( Phase ) + 0.5f;
			Position += TreeSwayScale * MEDIUM_TREE_SWAY_SCALE * WindMap * HeightFactor * wave * Offset * WindSpeed;

			return Position;
		}

		float3 WindTransformTall( float3 Position, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( Position, 1.0f ) ).xyz;
			float2 MapCoords = float2( WorldSpacePos.x / MapSize.x, 1.0 - WorldSpacePos.z / MapSize.y );

			float3 FlowMap = PdxTex2DLod0( FlowMapTexture, MapCoords ).rgb;
			float3 FlowDir = FlowMap.xyz * 2.0 - 1.0;
			FlowDir = FlowDir / ( length( FlowDir ) + 0.000001 ); // Intel did not like normalize()

			float WindMap = PdxTex2DLod0( WindMapTree, MapCoords ).r;

			float WorldX = GetMatrixData( WorldMatrix, 0, 3 );
			float WorldY = GetMatrixData( WorldMatrix, 2, 3 );
			float Noise = CalcNoise( GlobalTime * TreeSwayLoopSpeed + TreeSwayWindStrengthSpatialModifier * float2( WorldX, WorldY ) );
			float WindSpeed = Noise * Noise;
			float Phase = GlobalTime * TreeSwaySpeed * TALL_TREE_SWAY_SPEED + TreeSwayWindClusterSizeModifier * ( WorldX + WorldY );
			float3 Offset = normalize( float3( FlowDir.x, 0.0f, FlowDir.z ) );
			Offset = mul( Offset, CastTo3x3( WorldMatrix ) );
			float HeightFactor = saturate( Position.y * TreeHeightImpactOnSway * TALL_TREE_HEIGHT_IMPACT );
			HeightFactor *= HeightFactor;

			float wave = sin( Phase ) + 0.5f;
			Position += TreeSwayScale * TALL_TREE_SWAY_SCALE * WindMap * HeightFactor * wave * Offset * WindSpeed;

			return Position;
		}

		float3 SnapToWaterLevel( float3 PositionY, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( float3( 0.0f, 0.0f, 0.0f ), 1.0f ) ).xyz;

			float Height = GetHeight( WorldSpacePos.xz );
			PositionY += ( _WaterHeight - WorldSpacePos.y );

			return PositionY;
		}

	]]
}

PixelShader =
{
	Code
	[[
		void DebugRandomSeed( inout float3 Color, float Seed, float Variance = 1.0 )
		{
			Color = float3( 1.0, 0.0, 0.0 );
			float3 HSV_ = RGBtoHSV( Color );
			HSV_.x += float( Seed * Variance );
			Color = HSVtoRGB( HSV_ );
		}

		void AddBacklight( inout float3 Base, float3 AddColor, float3 Normal, float3 Light, float Intensity = 0.5 )
		{
				float3 InverseLight = saturate( 1.0 - dot( Normal, Light ) );
				Base = saturate( ( Base + ( AddColor * Intensity * InverseLight ) ) );
		}

		void ApplyStandardOfLiving( inout float3 Color, float2 Uv, float SolValue, float3 WorldSpacePos, float3 Normal )
		{
			float SolHigh = _SolDebugHigh;
			float SolLow = _SolDebugLow;

			if ( SolValue < 0.5 )
			{
				SolLow += SolValue * 2.0;
			}
			else
			{
				SolHigh += ( SolValue - 0.5 ) * 2.0;
			}

			SolHigh = saturate( SolHigh );
			SolLow = saturate( SolLow );

			float LocalHeight = WorldSpacePos.y - GetHeight( WorldSpacePos.xz );
			float TintAngleModifier = saturate( 1.0 - dot( Normal, float3( 0.0, 1.0, 0.0 ) ) );	// Removes tint from angles facing upwards
			float TintTopBlend = saturate( RemapClamped( LocalHeight - _SolHighTintHeight + _SolHighTintContrast, 0.0, _SolHighTintContrast, 0.0, 1.0 ) );
			float TintBottomBlend = ( 1.0 - RemapClamped( LocalHeight - _SolLowTintHeight, 0.0, _SolLowTintContrast, 0.0, 1.0 ) );

			float3 SolLowColor = PdxTex2D( SolLowTexture, Uv ).rgb;

			float3 HSV_ = RGBtoHSV( Color );
			HSV_.x *= _SolHighHue; 			// Hue
			HSV_.y *= _SolHighSaturation; 	// Saturation
			HSV_.z *= _SolHighValue; 		// Value
			float3 SaturatedColor = saturate( HSVtoRGB( HSV_ ) );

			Color = lerp( Color, SaturatedColor, TintTopBlend * SolHigh );
			Color = lerp( Color, Overlay( Color, SolLowColor ), TintBottomBlend * TintAngleModifier * SolLow );
		}
	]]
}
