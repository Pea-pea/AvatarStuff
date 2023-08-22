Shader "Custom/UnlitEye"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Hue("Hue: ", range(0,1)) = 0.5
        _Saturation("Saturation: ", range(0,1)) = 1
        _Value("Value: ", float) = 1
        _ColorStart("ColorStart: ", Range(0,0.5)) = 0.1
        _ColorEnd("ColorEnd: ", float) = 1
        _Exponent("Exponent: ", float) = 1
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

            half _ColorStart;
            half _ColorEnd;
            half _Exponent;
            half _Hue;
            half _Saturation;
            half _Value;
            half4 hsv;

            half InvLerp(half a, half b, half value)
            {
                return (value - a) / (b - a);
            }

            half3 HSVtoRGB(half _Hue, half _Saturation, half _Value)
            {
                half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                half3 p = abs(frac(half3(_Hue, _Hue, _Hue) + half3(K.x, K.y, K.z)) * 6.0 - half3(K.w, K.w, K.w));
                return _Value * lerp(half3(K.x, K.x, K.x), clamp(p - half3(K.x, K.x, K.x), 0.0, 1.0), _Saturation);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                hsv.xyz = HSVtoRGB(_Hue, _Saturation, _Value);
                //create radial gradient
                i.color.xyz = pow(lerp((hsv.xyz - half3(_ColorStart,_ColorStart,_ColorStart)), hsv.xyz, distance(i.uv.xy, half2(0.5,0.5))), _Exponent);                
                return i.color;
            }
            ENDCG
        }
    }
}
