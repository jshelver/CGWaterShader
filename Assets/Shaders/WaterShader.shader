Shader "Custom/WaterShader"
{
    Properties
    {
        _WaterColor ("Water Color", Color) = (0.5, 0.5, 0.5, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            fixed4 _WaterColor;

            v2f vert (appdata v)
            {
                float pi = 3.14159;
                v2f o;
                o.uv = v.uv;

                // Create a wave effect using sine function
                float amplitude = 1;
                float waveLength = 4 * pi;
                float frequency = (2 * pi) / waveLength;
                float waveSpeed = 1;
                o.uv.xy = amplitude * sin(o.uv.xy * frequency + _Time.y * waveSpeed);
                
                // Move the vertex height to altered UV value
                float3 vertexPosition = v.vertex;
                vertexPosition.y = o.uv.x + o.uv.y;

                o.vertex = UnityObjectToClipPos(vertexPosition);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _WaterColor;
            }
            ENDCG
        }
    }
}
