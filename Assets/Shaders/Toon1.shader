Shader "Luft/Toon/Toon01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        //Directional
        _RampTex ("Ramp Texture", 2D) = "white" {}
        //Ambient
        [HDR]_AmbientColor("Ambient Color", Color) = (0.4, 0.4, 0.4, 1.0)
        //Specular
        [HDR]_SpecularColor("Specular Color", Color) = (0.9, 0.9,0.9, 1.0)
        _Glossiness("Glossiness", Float) = 32
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "Toon01"
            Tags
            {
                "LightMode" = "UniversalForwardOnly"
            }
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half4 _AmbientColor;
            half4 _SpecularColor;
            half _Glossiness;
            CBUFFER_END

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_RampTex);        SAMPLER(sampler_RampTex);

            struct VertexInput
            {
                 float4 position    : POSITION;
                 float2 uv          : TEXCOORD0;
                 float4 normalOS    : NORMAL;
                 float4 tangentOS   : TANGENT;
            };

            struct VertexOutput
            {
                 float4 positionCS  : SV_POSITION;
                 float2 uv          : TEXCOORD0;
                 float3 normalWS    : TEXCOORD3;
                 float4 tangentWS   : TEXCOORD4;
                 float4 bitangentWS : TEXCOORD5;
                 float3 viewDirWS   : TEXCOORD6;
            };

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(i.position.xyz);
                o.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                o.positionCS = vertexInput.positionCS;
                VertexNormalInputs normalInput = GetVertexNormalInputs(i.normalOS.xyz, i.tangentOS);
                o.normalWS = normalInput.normalWS.xyz;
                o.tangentWS = float4(normalInput.tangentWS.xyz , 0.0);
                o.bitangentWS = float4(normalInput.bitangentWS.xyz , 0.0);
                o.uv = i.uv;
                return o;
            }

            half4 frag(VertexOutput i) : SV_Target
            {
                Light light = GetMainLight();
                half3 baseCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _BaseColor.rgb;

                float3 normalWS = normalize(i.normalWS);
                float3 viewDir = normalize(i.viewDirWS);
                float NoL = dot(normalWS, light.direction);
                float3 H = normalize(light.direction + viewDir);
                float NoH = dot(normalWS, H);

                float lightIntensity = smoothstep(0, 0.01, NoL);
                half specularIntensity = pow(NoH * lightIntensity, _Glossiness * _Glossiness);
                half specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                half3 specular = specularIntensity * _SpecularColor.rgb;

                float2 uv = float2(1 - (NoL * 0.5 + 0.5), 0.5);
                half3 rampCol = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, uv).rgb;
                half3 lightCol = rampCol * light.color * lightIntensity;
                half3 color =  baseCol * (_AmbientColor.rgb + lightCol + specular);
                return half4(color, 1.0);
            }

            ENDHLSL
        }
    }
}
