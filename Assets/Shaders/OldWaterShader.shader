Shader "Custom/OldWaterShader"
{
    Properties
    {
        _WaterColor ("Water Color", Color) = (0.5, 0.5, 0.5, 1)
        _Shininess ("Shininess", Float) = 50

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
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1; // World space normal
                float3 lightDirection : TEXCOORD2; // World space light direction
                float3 viewDirection : TEXCOORD3; // World space view direction
            };

            fixed4 _WaterColor;
            fixed _Shininess;

            v2f vert (appdata v)
            {
                float pi = 3.14159;
                v2f o;
                o.uv = v.uv;

                // Create a wave effect using sine function
                float amplitude = 1;
                float waveLength = 4 * pi;
                float frequency = (2 * pi) / waveLength;
                float waveSpeed = 0;
                o.uv.xy = amplitude * sin(o.uv.xy * frequency + _Time.y * waveSpeed);
                
                // Move the vertex height to altered UV value
                float3 vertexPosition = v.vertex;
                vertexPosition.y = o.uv.x + o.uv.y;

                o.vertex = UnityObjectToClipPos(vertexPosition);

                // Get the world space normal
                o.normal = UnityObjectToWorldNormal(v.normal);
                
                float3 worldPosition = mul(unity_ObjectToWorld, vertexPosition).xyz;
                o.viewDirection = _WorldSpaceCameraPos - worldPosition;

                o.lightDirection = normalize(UnityWorldSpaceLightDir(worldPosition));

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Normalize the normal, light and view direction (just in case)
                float3 normal = normalize(i.normal);
                float3 lightDirection = normalize(i.lightDirection);
                float3 viewDirection = normalize(i.viewDirection);

                // Lambertian diffuse
                float normalDotLight = max(dot(normal, lightDirection), 0); // Lock the value between 0 and 1
                fixed4 diffuseColor = _LightColor0 * _WaterColor * normalDotLight;

                // Blinn-Phong specular
                float3 halfVector = normalize(lightDirection + viewDirection);
                float normalDotHalf = max(dot(normal, halfVector), 0);
                float specularIntensity = pow(normalDotHalf, _Shininess);
                fixed4 specularColor = _LightColor0 * specularIntensity;

                // Combine the diffuse and specular color
                fixed4 finalColor = diffuseColor + specularColor;
                finalColor.a = _WaterColor.a;

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
