Shader "Custom/WaterShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Amplitude ("Amplitude", Float) = 1
        _WaveLength ("Wave Length", Float) = 6.28
        _WaveSpeed ("Wave Speed", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert

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

        float _Amplitude;
        float _WaveLength;
        float _WaveSpeed;

        void vert(inout appdata_full vertexData)
        {
            float3 vertexPosition = vertexData.vertex.xyz;
            
            // Alter vertex height with sine wave
            float frequency = 2 * UNITY_PI / _WaveLength;
            float phase = vertexPosition.x * frequency + _Time.y * _WaveSpeed;
            vertexPosition.y = _Amplitude * sin(phase);

            // Calculate the tangent vector by taking the derivative of the sine wave
            float derivative = _Amplitude * frequency * cos(phase);
            float3 tangentVector = normalize(float3(1, derivative, 0));
            // Because the sine wave is only in the y direction, the bitangent is just (0, 0, 1)
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
