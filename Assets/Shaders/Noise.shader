Shader "CG/Noise"
{
    Properties
    {
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        [Enum(Value, 0, Perlin, 1)] _NoiseType("Noise Type", Float) = 0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGRandom.cginc"

                // Declare used properties
                uniform float _NoiseScale;
                uniform float _NoiseType;

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos      : SV_POSITION;
                    float2 uv       : TEXCOORD0;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.uv = input.uv;
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {        
                    float2 uv = _NoiseScale * input.uv;
                    float c;
                    if (_NoiseType == 0)
                        c = value2d(uv);
                    else
                        c = perlin2d(uv);

                    c = c * 0.5 + 0.5; // Normalize to [0,1]
                    return fixed4(c, c, c, 1);
                }

            ENDCG
        }
    }
}
