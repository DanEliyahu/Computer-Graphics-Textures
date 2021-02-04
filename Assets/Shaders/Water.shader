Shader "CG/Water"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        _NoiseScale("Texture Scale", Range(1, 100)) = 10
        _TimeScale("Time Scale", Range(0.1, 5)) = 3
        _BumpScale("Bump Scale", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"
                #include "CGRandom.cginc"

                #define DELTA 0.01

                // Declare used properties
                uniform samplerCUBE _CubeMap;
                uniform float _NoiseScale;
                uniform float _TimeScale;
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
                    float4 pos      : SV_POSITION;
                    float2 uv       : TEXCOORD0;
                    float3 normalWorldPosition    : TEXCOORD1; // we need to use normal in World pos  
                    float3 worldPosition       : TEXCOORD2; // we need to use the pos in world Pos
                    float3 tangent       : TEXCOORD3; // we need to use normal in World pos  
                };

                // Returns the value of a noise function simulating water, at coordinates uv and time t
                float waterNoise(float2 uv, float t)
                {
                    return perlin3d(0.5 * float3( uv.x, uv.y, t)) + 0.5 * perlin3d(float3(uv.x, uv.y, t)) +
                        0.2 * perlin3d(float3(2.0 * (uv.x), 2.0 * (uv.y), 3.0 * t));
                }

                // Returns the world-space bump-mapped normal for the given bumpMapData and time t
                float3 getWaterBumpMappedNormal(bumpMapData i, float t)
                { 
                    //same implementaion as the  function we did to calculate the bump map in bricks only the heigth sample is difference   
                    float2 uv = _NoiseScale * i.uv; // never forget the Noise scale 
                    float f_pPlusdu = waterNoise(float2(uv.x + i.du, uv.y),t)*0.5+0.5; // normalize to [0,1] 
                    float f_pPlusdv = waterNoise(float2(uv.x, uv.y + i.dv),t)*0.5+0.5; // normalize to [0,1] 
                    float f_p = waterNoise(uv,t)*0.5+0.5; // normalize to [0,1] 
                    float fdu = (f_pPlusdu - f_p) / i.du;
                    float fdv = (f_pPlusdv - f_p) / i.dv;
                    float3 nh = normalize(float3(i.bumpScale * fdu * (-1), i.bumpScale * fdv * (-1), 1));
                    float3 b = normalize(cross(i.tangent, i.normal));
                    float3 newNormalWorld = normalize((i.tangent * nh.x) + (i.normal * nh.z) + (b * nh.y));
                    return newNormalWorld;
                }


                v2f vert (appdata input)
                {
                    v2f output;
                    output.uv = input.uv;
                    output.normalWorldPosition  = normalize(mul(unity_ObjectToWorld, float4(input.normal, 0.0)).xyz); // save the world pos of the normal 
                    output.tangent = normalize(mul(unity_ObjectToWorld, input.tangent).xyz);
                    float height = _BumpScale * (waterNoise(_NoiseScale * input.uv,_Time.y * _TimeScale)*0.5 + 0.5); // getting the height using noise 
                    float4 newPos = input.vertex + float4(input.normal * height,0); // calculte the new position in obj world 
                    output.pos = UnityObjectToClipPos(newPos); 
                    output.worldPosition = mul(unity_ObjectToWorld, newPos);
                    return output;
                }

                fixed4 frag(v2f input) : SV_Target
                {
                    // init bumpMapData and cacultae the new normal position 
                    float3 n = normalize(input.normalWorldPosition);
                    float3 t = normalize(input.tangent);
                    bumpMapData i;
                    i.normal = n;
                    i.tangent = t;
                    i.uv = input.uv;
                    i.du = DELTA;
                    i.dv = DELTA;
                    i.bumpScale = _BumpScale;
                    float3 newn = getWaterBumpMappedNormal(i,_Time.y * _TimeScale);
                    // calculate the reflected color using the new normal 
                    float3 v = normalize(_WorldSpaceCameraPos - input.worldPosition);
                    float3 r = (2 * (dot(v,newn)) * newn) - v;
                    fixed4 reflectedColor = texCUBE(_CubeMap, r);
                    fixed4 color = (1 - max(0,dot(newn,v)) + 0.2) * reflectedColor;
                    return color;
                }

            ENDCG
        }
    }
}