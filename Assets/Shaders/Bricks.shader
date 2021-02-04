Shader "CG/Bricks"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap("Specular Map", 2D) = "defaulttexture" {}
        _Shininess("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap("Height Map", 2D) = "defaulttexture" {}
        _BumpScale("Bump Scale", Range(-100, 100)) = 40
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "CGUtils.cginc"
            
            // constants
            #define BUMP_SCALE_FACTOR 0.0001;

            // Declare used properties
            uniform sampler2D _AlbedoMap;
            uniform float _Ambient;
            uniform sampler2D _SpecularMap;
            uniform float _Shininess;
            uniform sampler2D _HeightMap;
            uniform float4 _HeightMap_TexelSize;
            uniform float _BumpScale;

            struct appdata
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                float2 uv       : TEXCOORD0;
            };

            struct v2f
            {
                float3 worldPosition : TEXCOORD2;
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD3;
                float4 pos : SV_POSITION;
                float2 uv  : TEXCOORD0;
            };

            v2f vert(appdata input)
            {
                v2f output;
                output.pos = UnityObjectToClipPos(input.vertex);
                output.uv = input.uv;
		// Transfer normal, tangent and position to World-Space to be used in frag shader
                output.normal = normalize(mul(unity_ObjectToWorld, float4(input.normal, 0.0)).xyz);
                output.tangent = normalize(mul(unity_ObjectToWorld, input.tangent).xyz);
                output.worldPosition = mul(unity_ObjectToWorld, input.vertex);
                return output;
            }

            fixed4 frag(v2f input) : SV_Target
            {
                float3 n = normalize(input.normal);
                float3 t = normalize(input.tangent);
		// fill bumpMapData with needed information for bump mapping
                bumpMapData i;
                i.normal = n;
                i.tangent = t;
                i.uv = input.uv;
                i.heightMap = _HeightMap;
                i.du = _HeightMap_TexelSize.x;
                i.dv = _HeightMap_TexelSize.y;
                i.bumpScale = _BumpScale * BUMP_SCALE_FACTOR;
                float3 newn = getBumpMappedNormal(i);
                float3 l = normalize(_WorldSpaceLightPos0.xyz);
                float3 v = normalize(_WorldSpaceCameraPos - input.worldPosition);
		// sample textures and compute shading and lighting using the bump mapped normals
                fixed4 albedo = tex2D(_AlbedoMap,input.uv);
                fixed4 specular = tex2D(_SpecularMap, input.uv);
                return fixed4(blinnPhong(newn,v,l, _Shininess, albedo, specular, _Ambient),1);
            }

        ENDCG
        }
    }
}
