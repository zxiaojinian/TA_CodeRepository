Shader "Code Repository/Scene/Rain" 
{
	Properties 
	{
		_MainTex ("MainTex", 2D) = "white" {}
	}
	SubShader 
	{
		Tags 
		{
			"RenderPipeline"="UniversalPipeline"
		}

		HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			half3 _RainColor;
			float4 _RainScale_Layer12;
			float4 _RainScale_Layer34;
			float4 _RotateSpeed;
			float4 _RotateAmount;
			float4 _DropSpeed;
			
			TEXTURE2D(_DistortionTexture);
			SAMPLER(sampler_DistortionTexture);

			TEXTURE2D(_NoiseTexture);
			SAMPLER(sampler_NoiseTexture);			
			
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			//SAMPLER(sampler_linear_repeat).

			TEXTURE2D(_RainShapeTex);
			SAMPLER(sampler_RainShapeTex);
		ENDHLSL

		//Pass
		//{
		//	Name "Rain Mask"
		//	HLSLPROGRAM
		//	#pragma vertex vertex
		//	#pragma fragment fragment

		//	struct Attributes 
		//	{
		//		float4 positionOS	: POSITION;
		//		float2 uv		    : TEXCOORD0;
		//	};

		//	struct Varyings 
		//	{
		//		float4 positionCS 	: SV_POSITION;
		//		float2 UV			: TEXCOORD0;	
		//		float4 UVLayer12	: TEXCOORD1;
		//		float4 UVLayer34	: TEXCOORD2;
		//		//float4 DistoUV		: TEXCOORD3;
		//		//float4 BlendUV		: TEXCOORD4;
		//	};

		//	Varyings vertex(Attributes IN) 
		//	{
		//		Varyings OUT;
		//		OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
		//		OUT.UV = IN.uv;

		//		float4 UVLayer12 = IN.uv.xyxy;
		//		float2 SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.xy + float2(0, 0.1)) * _RotateAmount.xy * 0.1;
		//		float4 Cosines = float4(cos(SinT), sin(SinT));
		//		float4 CenteredUV = UVLayer12 - 0.5;
		//		float4 RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
		//								 , dot(Cosines.zx, CenteredUV.xy)
		//								 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
		//								 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
		//		UVLayer12 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.xxyy;
		//		UVLayer12 *= _RainScale_Layer12;
		//		OUT.UVLayer12 = UVLayer12;

		//		float4 UVLayer34 = IN.uv.xyxy;
		//		SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.zw + float2(0, 0.1)) * _RotateAmount.zw * 0.1;
		//		Cosines = float4(cos(SinT), sin(SinT));
		//		CenteredUV = UVLayer34 - 0.5;
		//		RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
		//								 , dot(Cosines.zx, CenteredUV.xy)
		//								 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
		//								 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
		//		UVLayer34 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.zzww;
		//		UVLayer34 *= _RainScale_Layer34;
		//		OUT.UVLayer34 = UVLayer34;
		//		return OUT;
		//	}

		//	half4 fragment(Varyings IN) : SV_Target 
		//	{
		//		//// Layer 3
		//		//float2 NoiseUV = SAMPLE_TEXTURE2D(_DistortionTexture, sampler_DistortionTexture, IN.DistoUV.xy).rg + SAMPLE_TEXTURE2D(_DistortionTexture, sampler_DistortionTexture, IN.DistoUV.zw).rg;
		//		//NoiseUV = NoiseUV * IN.UV.y * 2.0f + float2(1.5f, 0.7f) * IN.UV.xy + float2(0.1f, -0.2f) * _Time.yy;
		//		//float LayerMask3 = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture,  NoiseUV) + 0.32f;
		//		//LayerMask3 = saturate(pow(2.0f * LayerMask3, 2.95f) * 0.6f);

		//		//// Layer 4
		//		//float LayerMask4 = tex2D(NoiseTexture, BlendUV.xy)
		//		//				   + tex2D(NoiseTexture, BlendUV.zw) + 0.37f;

		//		// Background Pixel depth - in view space
		//		float Depth = CalcSceneDepth(ScreenPosition);
		//		// Layers Depth tests :
		//		float2 VirtualDepth = 0;
		//		// Constant are based on layers distance
		//		VirtualDepth.x = tex2D(Heightmap, UVLayer12.xy).r * RainDepthRange.x + RainDepthStart.x;
		//		VirtualDepth.y = tex2D(Heightmap, UVLayer12.zw).r * RainDepthRange.y + RainDepthStart.y;
		//		// Mask using virtual position and the scene depth
		//		float2 OcclusionDistance = saturate((Depth - VirtualDepth) * 10000.0f);
		//		// Calc virtual position
		//		float3 Dir = normalize(PixelPosition);   // Cylinder is link to camera
		//		float3 VirtualPosition1WS = CameraPositionWS.xyz + Dir * DepthLayers.x;
		//		float3 VirtualPosition2WS = CameraPositionWS.xyz + Dir * DepthLayers.y;
		//		// Mask using virtual layer depth and the depth map
		//		// RainDepthMapTest use the same projection matrix than
		//		// the one use for render depth map
		//		float2 Occlusion= 0;
		//		Occlusion.x = RainDepthMapTest(VirtualWPos1);
		//		Occlusion.y = RainDepthMapTest(VirtualWPos2);
		//		Occlusion*= OcclusionDistance;

		//		//OutColor = float4(Occlusion.xy, LayerMask3, LayerMask4);
		//		half4 OutColor = float4(Occlusion.xy, 1, 1);
		//		return OutColor;
		//	}
		//	ENDHLSL
		//}

		Pass
		{
			Name "Rain Merge"
			HLSLPROGRAM
			#pragma vertex vertex
			#pragma fragment fragment

			struct Attributes 
			{
				float4 positionOS	: POSITION;
				float2 uv		    : TEXCOORD0;
			};

			struct Varyings 
			{
				float4 positionCS 	: SV_POSITION;
				float2 uv			: TEXCOORD0;	
				float4 UVLayer12	: TEXCOORD1;
				float4 UVLayer34	: TEXCOORD2;
			};

			Varyings vertex(Attributes IN) 
			{
				Varyings OUT;
				OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
				OUT.uv = IN.uv;

				float4 UVLayer12 = IN.uv.xyxy;
				float2 SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.xy + float2(0, 0.1)) * _RotateAmount.xy * 0.1;
				float4 Cosines = float4(cos(SinT), sin(SinT));
				float4 CenteredUV = UVLayer12 - 0.5;
				float4 RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer12 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.xxyy;
				UVLayer12 *= _RainScale_Layer12;
				OUT.UVLayer12 = UVLayer12;

				float4 UVLayer34 = IN.uv.xyxy;
				SinT = sin(_Time.xx * TWO_PI * _RotateSpeed.zw + float2(0, 0.1)) * _RotateAmount.zw * 0.1;
				Cosines = float4(cos(SinT), sin(SinT));
				CenteredUV = UVLayer34 - 0.5;
				RotatedUV = float4(dot(Cosines.xz * float2(1, -1), CenteredUV.xy)
										 , dot(Cosines.zx, CenteredUV.xy)
										 , dot(Cosines.yw * float2(1, -1), CenteredUV.zw)
										 , dot(Cosines.wy, CenteredUV.zw)) + 0.5;
				UVLayer34 = RotatedUV + float4(0, 1, 0, 1) * _Time.x * _DropSpeed.zzww;
				UVLayer34 *= _RainScale_Layer34;
				OUT.UVLayer34 = UVLayer34;
				return OUT;
			}

			half4 fragment(Varyings IN) : SV_Target 
			{
				half4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

				half4 mask = 1;

				half4 layer = 0;
				layer.x = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.xy).r;
				layer.y = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer12.zw).r;
				layer.z = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.xy).r;
				layer.w = SAMPLE_TEXTURE2D(_RainShapeTex, sampler_RainShapeTex, IN.UVLayer34.zw).r;

				half rainShape = dot(layer, mask);
				rainShape = saturate(rainShape);

				half3 finalColor = lerp(mainTexColor.rgb, _RainColor, rainShape);
				return half4(finalColor, mainTexColor.a);
			}
			ENDHLSL
		}
	}
}