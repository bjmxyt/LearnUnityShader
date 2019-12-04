
Shader"Custom/NormalMapTangentSpace"
{
	Properties{
		_Color("Color Tint", Color) = (1, 1, 1, 1)//物体颜色
		_MainTex("Main Texture", 2D) = "white"{}//纹理贴图
		_BumpMap("Normal Map", 2D) = "bump"{}//法线贴图
		_BumpScale("Bump Scale", Range(0.0, 1)) = 1.0//凹凸程度
		_Specular("Specular Color", Color) = (1, 1, 1, 1)//高光颜色
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}

	SubShader{
		Pass{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include"Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;//Main Texture Scale and Translation
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex: POSITION;
				float3 normal:NORMAL;
				float4 tangent: TANGENT;
				float4 texcoord: TEXCOORD0;
			};

			struct v2f{
				float4 pos: SV_POSITION;
				float4 uv: TEXCOORD0;
				float3 lightDir: TEXCOORD1;
				float3 viewDir: TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f o;

				//将坐标从模型空间转换到齐次裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);
				
				//纹理贴图和法线贴图的uv通道
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				//在模型空间中计算副切线
				float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				//计算从模型空间转到切线空间的转换矩阵（目标空间坐标系的基按行排列）
				float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

				//将光线方向和视线方向从模型空间转至切线空间
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

				//返回
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				
				//单位化
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				//按照法线贴图的uv坐标得到当前点下的原始法线数据
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal;

				//使用内置函数进行逆转换，像素颜色值和对应的法向量关系为: pixel = (normal + 1)/ 2;(pixel 和 normal均为vector3)
				tangentNormal = UnpackNormal(packedNormal);
				//乘以用以控制凹凸程度的BumpScale
				tangentNormal.xy *= _BumpScale;
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
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

				//返回像素最终颜色
				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}
	}

}