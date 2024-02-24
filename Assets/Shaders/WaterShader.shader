Shader "Custom/WaterShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _WaveA ("Wave A (dir, steep, length)", Vector) = (1, 1, 0.5, 6.28)
        _WaveB ("Wave B (dir, steep, length)", Vector) = (1, 0, 0.3, 4)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard alpha vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #include "UnityCG.cginc"
        #include "LookingThroughWater.cginc"

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float4 _WaveA;
        float4 _WaveB;

        float3 GerstnerWave(float4 wave, float3 position, inout float3 tangent, inout float3 binormal)
        {
            // Get wave parameters
            float2 direction = normalize(wave.xy);
            float steepness = wave.z;
            float wavelength = wave.w;

            // Calculate wave modifiers
            float frequency = 2 * UNITY_PI / wavelength;
            float waveSpeed = sqrt(9.81 / frequency); // w = sqrt(g / f)
            float phase = frequency * dot(direction, position.xz) + _Time.y * waveSpeed;
            float amplitude = steepness / frequency;

            // Calculate tangent
            tangent += float3(
                -direction.x * direction.x * steepness * sin(phase), // Tx = -Dx^2 * A * sin(p)
                direction.x * steepness * cos(phase), // Ty = Dx * A * cos(p)
                -direction.x * direction.y * steepness * sin(phase) // Tz = -Dx * Dy * A * sin(p)
            );

            // Calculate binormal
            binormal += float3(
                -direction.x * direction.y * steepness * sin(phase), // Bx = -Dx * Dy * A * sin(p)
                direction.y * steepness * cos(phase), // By = Dy * A * cos(p)
                -direction.y * direction.y * steepness * sin(phase) // Bz = -Dy^2 * A * sin(p)
            );

            // Calculate change in position due to wave
            return float3(
                direction.x * amplitude * cos(phase), // x = Dx * A * cos(p)
                amplitude * sin(phase), // y = A * sin(p)
                direction.y * amplitude * cos(phase) // z = Dy * A * cos(p)
            );
        }

        void vert(inout appdata_full vertexData)
        {
            // Get current vertex position
            float3 vertexPosition = vertexData.vertex.xyz;

            // Initialize tangent and binormal
            float3 tangent = float3(1, 0, 0);
            float3 binormal = float3(0, 0, 1);

            // Calculate total wave displacement
            float3 updatedVertexPosition = vertexPosition;
            updatedVertexPosition += GerstnerWave(_WaveA, vertexPosition, tangent, binormal);
            updatedVertexPosition += GerstnerWave(_WaveB, vertexPosition, tangent, binormal);

            // Calculate normal
            float3 normal = normalize(cross(binormal, tangent)); // N = B x T

            vertexData.vertex.xyz = updatedVertexPosition;
            vertexData.normal = normal;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;

            o.Albedo = ColorBelowWater(IN.screenPos);
            o.Alpha = c.a;
        }
        ENDCG
    }
}
