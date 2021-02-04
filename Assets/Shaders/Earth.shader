Shader "CG/Earth"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(1, 100)) = 30
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "black" {}
        _AtmosphereColor ("Atmosphere Color", Color) = (0.8, 0.85, 1, 1)
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
                uniform sampler2D _CloudMap;
                uniform fixed4 _AtmosphereColor;

                struct appdata
                { 
                    float4 vertex : POSITION;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float3 worldPosition: TEXCOORD0;
                    float3 normal: TEXCOORD1;
                    float3 objectPosition: TEXCOORD2;  // To calculate the UV according to object space 
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    // To find the normal at the point we can subtract the point coords from the origin of the sphere
                    // to get the desired vector. In object space the origin of the sphere is (0,0,0) and so we get
                    // that the normal corresponds to the value of the vertex position.
                    float3 normalobj = normalize(input.vertex);
                    output.normal = mul(unity_ObjectToWorld, float4(normalobj, 0.0).xyz);
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.worldPosition = mul(unity_ObjectToWorld, input.vertex);
                    output.objectPosition = input.vertex;
                    return output;
                }

                fixed4 frag(v2f input) : SV_Target
                {
                   float2 uv = getSphericalUV(input.objectPosition); // sending the object position to get UV coords
                   float3 tangent = normalize(cross(input.normal , float3(0,1,0))); // getting the tangent vector
                   bumpMapData i;
                   i.normal = normalize(input.normal);
                   i.tangent = tangent;
                   i.uv = uv;
                   i.heightMap = _HeightMap;
                   i.du = _HeightMap_TexelSize.x;
                   i.dv = _HeightMap_TexelSize.y;
                   i.bumpScale = _BumpScale * BUMP_SCALE_FACTOR;
                   float3 newn = getBumpMappedNormal(i); // get bump mapped normal
                   // sample all needed textures and compute shading and lighting to get final color
                   fixed4 specular = tex2D(_SpecularMap, uv);
                   // make sure bump mapping doesn't affect water bodies who are generally flat
                   float3 finalNoraml = (1 - specular) * newn + specular * i.normal; 
                   fixed4 albedo = tex2D(_AlbedoMap, uv);
                   float3 l = normalize(_WorldSpaceLightPos0.xyz);
                   float3 v = normalize(_WorldSpaceCameraPos - input.worldPosition);
                   float Lambert = max(0, dot(i.normal, l));
                   fixed4 atmosphereColor = (1 - max(0, dot(i.normal, v))) * (sqrt(Lambert)) * _AtmosphereColor;
                   fixed4 cloudsColor = tex2D(_CloudMap, uv) * (sqrt(Lambert) + _Ambient);
                   return fixed4(blinnPhong(newn, v, l, _Shininess, albedo, specular, _Ambient), 1)+ atmosphereColor+ cloudsColor;
                }

            ENDCG
        }
    }
}