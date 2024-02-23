Shader "Custom/WaterShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Steepness ("Wave Steepness", Range(0, 1)) = 0.5
        _WaveLength ("Wave Length", Float) = 6.28
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _Steepness;
        float _WaveLength;

        void vert(inout appdata_full vertexData)
        {
            float3 vertexPosition = vertexData.vertex.xyz;
            
            // Alter vertex height with gerstner wave
            float frequency = 2 * UNITY_PI / _WaveLength;
            float waveSpeed = sqrt(9.81 / frequency); // w = sqrt(g / f)
            float phase = vertexPosition.x * frequency + _Time.y * waveSpeed;
            float amplitude = _Steepness / frequency;
            vertexPosition.x += amplitude * cos(phase); // f(x, t) = x + A * cos(f * x + t * w)
            vertexPosition.y = amplitude * sin(phase); // f(y, t) = A * cos(f * y + t * w)

            // Calculate the tangent vector by taking the derivative of the wave
            float xDerivative = 1 - _Steepness * frequency * sin(phase); // df/dx = 1 - A * f * sin(f * x + t * w)
            float yDerivative = _Steepness * frequency * cos(phase); // df/dy = A * f * cos(f * y + t * w)
            float3 tangentVector = normalize(float3(xDerivative, yDerivative, 0));
            // Because the wave is only in the x direction, the bitangent is just (0, 0, 1)
            // N = T x B
            float3 normalVector = normalize(float3(-tangentVector.y, tangentVector.x, 0));

            vertexData.vertex.xyz = vertexPosition;
            vertexData.normal = normalVector;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
