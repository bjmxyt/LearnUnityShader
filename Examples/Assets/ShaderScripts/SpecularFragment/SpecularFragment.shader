// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/DiffuseShadingVertex"
{
    Properties
    {
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
    }

	SubShader{
		Pass{
			Tags {"LightMode" = "ForwardBase"}

		CGPROGRAM

		#pragma vertex vert
		#pragma fragment frag

		#include "Lighting.cginc"

		fixed4 _Diffuse;
		fixed4 _Specular;
		float _Gloss;

		struct a2v{
			float4 vertex: POSITION;
			float3 normal: NORMAL;
		};

		struct v2f{
			float4 pos: SV_POSITION;
			float3 normal: TEXCOORD0;
			float4 worldPos: TEXCOORD1;
		};

		v2f vert(a2v v){
			v2f o;

			o.pos = UnityObjectToClipPos(v.vertex);
			o.normal = v.normal;
			o.worldPos = mul(unity_ObjectToWorld, v.vertex);
			return o;

		}

		fixed4 frag(v2f i): SV_Target{
			
			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
			
			float3 worldNormal = normalize(mul(unity_ObjectToWorld, i.normal));
			float3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

			fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb  * saturate(dot(worldNormal, worldLightDir));

			float3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));

			float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

			//Phong Model
			//fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

			//Blinn-Phong Model
			fixed3 halfDir = normalize(worldLightDir + viewDir);
			fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

			fixed3 color = ambient + diffuse + specular;

			return fixed4(color, 1.0);
		}

		ENDCG
		}
	}
    
}
