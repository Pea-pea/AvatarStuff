Shader "Custom/UnlitGradients"
{
    Properties
    {
        _Hue("Hue: ", range(0,1)) = 0.5
        _Saturation("Saturation: ", range(0,1)) = 1
        _Value("Value: ", float) = 1
        _ColorStart("ColorStart: ", Range(0,1)) = 0.5
        _ColorEnd("ColorEnd: ", float) = 0.5
        _Exponent("Exponent: ", float) = 1

        _AudioLink ("AudioLink Texture", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert //runs on every vertex onscreen
            #pragma fragment frag //runs on every pixel onscreen 

            #include "UnityCG.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc" //audiolink cginc
            
            struct appdata //data coming from the mesh
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f //vert to frag
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : TEXCOORD1;
                half3 normal : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _ColorStart;
            float _ColorEnd;
            float _Exponent;
            float _Hue;
            float _Saturation;
            float _Value;
            float _ShiftedColorStart;
            float _ShiftedHue;
            float _ShiftedValue;

            half4 hsv;

            float InvLerp(float a, float b, float value)
            {
                return (value - a) / (b - a);
            }

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

                //shift _Hue with audiolink 4 band over time
                _ShiftedHue = _Hue + ((AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 1, 1 ) ).r % 1000000) / 1000000.0); 
                //_ShiftedHue = saturate(_ShiftedHue);
                
                //shift _ColorStart with audiolink 4 band
                _ShiftedColorStart = saturate(_ColorStart + (AudioLinkData( ALPASS_FILTEREDAUDIOLINK  + uint2( 10, 0 ) ).rrrr * .2));
                
                //shift _Value with audiolink 4 band
                _ShiftedValue = saturate(_Value + AudioLinkData( ALPASS_FILTEREDAUDIOLINK  + uint2( 10, 2 ) ).r);

                //make _Value bigger at the edges of each hair strand using normals and camera direction
                //_ShiftedValue += 2 * (1 - saturate(dot(v.normal, normalize(UnityWorldSpaceViewDir(o.vertex)))));

                //gradient stuff:
                float t = InvLerp(_ShiftedColorStart, _ColorEnd, pow(v.uv.x, _Exponent));
                hsv.xyz = HSVtoRGB(_ShiftedHue, _Saturation, _ShiftedValue);
                o.color = lerp(half4(0,0,0,0), hsv, t);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.color.xyz -= saturate(AudioLinkLerpMultiline( ALPASS_WAVEFORM  + float2(i.uv.y * 512, 0 ) ).rrr ) / 5;
                return i.color;
            }
            ENDCG
        }
    }
}
