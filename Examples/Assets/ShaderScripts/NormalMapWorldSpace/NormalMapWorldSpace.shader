// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"Custom/Normal Map World Space"
{
	Properties{
		_Color("Tint Color", Color) = (1, 1, 1, 1)
		_MainTex("Main Texture", 2D) = "white"{}
		_BumpMap("Normal Map", 2D) = "bump"{}
		_BumpMapScale("BumpMapScale", Range(0.0, 1)) = 1
		_SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
		_Gloss("Gloss Scale", Range(1.0, 256)) = 20
	}
	SubShader{
		Pass{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM

			#pragma vertex Vert
			#pragma fragment Frag

			#include"Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpMapScale;
			fixed3 _SpecularColor;
			float _Gloss;

			struct a2v{
				float4 vertex: POSITION;
				float3 normal: NORMAL;
				float4 tangent: TANGENT;
				float4 texcoord:TEXCOORD0;
			};

			struct v2f{
				float4 pos: SV_POSITION;
				float4 uv: TEXCOORD0;
				float3 lightDir: TEXCOORD1;
				float3 viewDir: TEXCOORD2;
			};

			v2f Vert(a2v v){
				v2f o;
				//将模型坐标从模型空间转至齐次裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);

				//传递纹理贴图以及法线贴图的uv坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				float3 worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
				float3 worldTangent = normalize(mul(unity_ObjectToWorld, v.tangent)).xyz;
				float3 biNormal = cross(normalize(worldNormal), normalize(worldTangent)) * v.tangent.w;

				float3x3 rotation = float3x3(worldTangent, biNormal, worldNormal);

				o.lightDir = mul(rotation, WorldSpaceLightDir(v.vertex));
				o.viewDir = mul(rotation, WorldSpaceViewDir(v.vertex));

				return o;
			}
			fixed4 Frag(v2f i) : SV_Target{
				
				//单位化
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				//按照法线贴图的uv坐标得到当前点下的原始法线数据
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal;

				//使用内置函数进行逆转换，像素颜色值和对应的法向量关系为: pixel = (normal + 1)/ 2;(pixel 和 normal均为vector3)
				tangentNormal = UnpackNormal(packedNormal);
				//乘以用以控制凹凸程度的BumpScale
				tangentNormal.xy *= _BumpMapScale;
				//计算改变凹凸程度后的xy值对应下的z值（简单的勾股定理）
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				//根据纹理贴图的uv坐标得到当前点的贴图颜色
				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;

				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				//漫反射光（切线空间下）
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				//使用Blinn-Phong模型计算Specular（切线空间下）
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

				//返回像素最终颜色
				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}

	}
}