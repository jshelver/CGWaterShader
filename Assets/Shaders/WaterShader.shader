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
        _Direction ("Wave Direction (2D)", Vector) = (1, 0, 0, 0)
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
        float2 _Direction;

        void vert(inout appdata_full vertexData)
        {
            float3 vertexPosition = vertexData.vertex.xyz;
            
            // Alter vertex height with gerstner wave
            float frequency = 2 * UNITY_PI / _WaveLength;
            float waveSpeed = sqrt(9.81 / frequency); // w = sqrt(g / f)
            float2 direction = normalize(_Direction);
            float phase = frequency * dot(direction, vertexPosition.xz) + _Time.y * waveSpeed;
            float amplitude = _Steepness / frequency;

            vertexPosition.x += direction.x * amplitude * cos(phase); // f(x, t) = x + Dx * A * cos(p)
            vertexPosition.y = amplitude * sin(phase); // f(y, t) = A * cos(f * y + t * w)
            vertexPosition.z += direction.y * amplitude * cos(phase); // f(z, t) = z + Dy * A * cos(p)

            // Calculate the tangent vector by taking the derivative of the wave
            float3 tangent = float3(
                1 - direction.x * direction.x * _Steepness * sin(phase), // Tx = 1 - Dx^2 * A * sin(p)
                direction.x * _Steepness * cos(phase), // Ty = Dx * A * cos(p)
                -direction.x * direction.y * _Steepness * sin(phase) // Tz = -Dx * Dy * A * sin(p)
            );
            
            // Calculate binormal
            float3 binormal = float3(
                -direction.x * direction.y * _Steepness * sin(phase), // Bx = -Dx * Dy * A * sin(p)
                direction.y * _Steepness * cos(phase), // By = Dy * A * cos(p)
                1 - direction.y * direction.y * _Steepness * sin(phase) // Bz = 1 - Dy^2 * A * sin(p)
            );
            
            // Calculate normal
            float3 normalVector = normalize(cross(binormal, tangent)); // N = B x T

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
