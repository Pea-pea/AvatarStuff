Shader "Custom/UnlitEye"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Hue("Hue: ", range(0,1)) = 0.5
        _Saturation("Saturation: ", range(0,1)) = 1
        _Value("Value: ", float) = 1
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
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc" //audiolink cginc

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Hue;
            float _Saturation;
            float _Value;
            half4 hsv;


            float3 HSVtoRGB(float _Hue, float _Saturation, float _Value)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(float3(_Hue, _Hue, _Hue) + float3(K.x, K.y, K.z)) * 6.0 - float3(K.w, K.w, K.w));
                return _Value * lerp(float3(K.x, K.x, K.x), clamp(p - float3(K.x, K.x, K.x), 0.0, 1.0), _Saturation);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;

                hsv.xyz = HSVtoRGB(_Hue, _Saturation, _Value);
                //create radial gradient
                float dist = distance(o.uv.xy, float2(0.5,0.5));
                o.color.xyz = lerp(hsv.xyz, half4(0,0,0,0), dist);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                return i.color;
            }
            ENDCG
        }
    }
}
