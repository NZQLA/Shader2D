// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/MatPlat" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_AlphaScale ("Alpha Scale", Range(0, 1)) = 1
		_Hight("Hight",float) = 1
		_TimeScale("TimeScale",float) = 1 
		_MainTexTill("MainTexTill",Vector) = (1,1,1)
		_AniTime("AniTime",float) = 1
		
	}
	SubShader {
//		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha,One Zero
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
//            #pragma geometry geom
			
			#include "Lighting.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _AlphaScale;
			float _Hight;
			float _TimeScale;
			float _offsetY;
			float4 _MainTexTill;
			float _AniTime;
			float _AniValue;
			float _Cur;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float4 texcoord : TEXCOORD0;   
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};
			
			
			float GetOffsetY(float aninValue,float time)
			{
			  float timeFly  = floor(time - aninValue);
			  if(timeFly>_AniTime)
			  {
			    return 0;
			  }
			  
			  return timeFly/_AniTime;
			}
			
			
			v2f vert(a2v v) {
				v2f o;
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			
			    _AniValue = ceil(o.uv.x);
			    _Cur = floor(_Time.y*_TimeScale);
			    _offsetY = GetOffsetY(_AniValue,_Cur);
			
			
//			    _offsetY =  _Hight - _Time.y*_TimeScale;
//			    _offsetY = GetOffsetY(_AniValue,_Time.y*_TimeScale);
//			    v.vertex.y += _offsetY;

			    v.vertex += v.normal*_offsetY;
			
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				
				return o;
			}
			
			
			
//	[maxvertexcount(3)]                                                //表示最后outputStream中的v2f数据是3个
//	void geom(triangle v2f input[3], inout TriangleStream<v2f> OutputStream)
//	{
//		v2f test = (v2f)0;//这里直接重构v2f这个结构体，也可以定义v2g，g2f两个结构体来完成这个传递过程
//		float3 normal = normalize(cross(input[1].worldPos.xyz - input[0].worldPos.xyz, input[2].worldPos.xyz - input[0].worldPos.xyz));
//		for (int i = 0; i < 3; i++)
//		{
//			test.worldNormal = normal;  //顶点变为这个三角图元的法线方向
//			test.pos = input[i].pos;
//			test.pos += float4(test.worldNormal*_Hight,0);
//			test.uv = input[i].uv;
//			OutputStream.Append(test);
//		}
//    }
			
			
			
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				fixed4 texColor = tex2D(_MainTex, i.uv);
				
			    // AlphaTest
//				texColor.a = _Time.y - i.uv.x - i.uv.y;
//				clip (_Time.y - i.uv.x - i.uv.y);
//				clip (_Time.y*_TimeScale - i.uv.x);
				clip (floor( _Time.y*_TimeScale) - ceil(i.uv.x)- ceil(i.uv.y));
				
				
				fixed3 albedo = texColor.rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
				
				return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
//				return fixed4(ambient + diffuse, _Time.y*_TimeScale/_MainTexTill.x);

			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/VertexLit"
}
