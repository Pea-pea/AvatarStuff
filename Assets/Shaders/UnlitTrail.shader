Shader "Custom/UnlitTrail"
{
    Properties
    {
        [Header(Gradient)]
        _ColorOffset("Color Offset", Range(0, 1)) = 0
        
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _Band("Band", int) = 1
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

            float _ColorOffset;
            float4 Color0;
            float4 Color1;
            float _Band;
            float _AudioHue;

            //HSV to RGB conversion from: https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
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
                o.uv = v.uv;
                
                //shift color with audiolink 4 band over time
                _AudioHue = (AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 1, _Band ) ).r % 1000000) / 1000000.;
                Color0.xyz = HSVtoRGB(1 - _AudioHue, 1, 1);
                Color0.w = 1;

                Color1.xyz = HSVtoRGB(_AudioHue, 1, 1);
                Color1.w = 1;

                o.color = lerp(Color0, Color1, o.uv.x);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
}
