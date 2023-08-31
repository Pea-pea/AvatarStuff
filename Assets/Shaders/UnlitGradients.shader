Shader "Custom/UnlitGradients"
{
    Properties
    {   
        [Header(Colors)]
        _Hue("Hue: ", range(0,1)) = 0.5
        _Saturation("Saturation: ", range(0,1)) = 1
        _Value("Value: ", float) = 1
           
        [Header(Gradient Controls)]
        _ColorStart("ColorStart: ", Range(0,1)) = 0.5
        _ColorEnd("ColorEnd: ", float) = 0.5
        _Exponent("Exponent: ", float) = 1

        [Header(Audiolink Bands)]
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _ColorStartBand("ColorStartBand: ", int) = 0
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _HueBand("HueBand: ", int) = 1
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _ValueBand("ValueBand: ", int) = 2
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _LinesBand("LinesBand: ", int) = 3

        [Space(20)] _AudioLink ("AudioLink Texture", 2D) = "black" {}

        [Curve]_CurveTest ("CurveTest", 2D) = "white" { }

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
            };

            struct v2f //vert to frag
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : TEXCOORD1;
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

            int _ColorStartBand;
            int _HueBand;
            int _ValueBand;
            int _LinesBand;

            half4 hsv;

            //Inverse Lerp function from: https://forum.unity.com/threads/lerp-from-1-to-0.380788/
            float InvLerp(float a, float b, float t)
            {
                return (t - a) / (b - a);
            }

            //Exponential Interpolation function from: https://www.shadertoy.com/view/4t2SDh
            float4 ExponentialInterpolate(float4 a, float4 b, float t, float exponent)
            {
                //equation which interpolates between two colors exponentially
                return (1 - pow(1 - t, exponent)) * a + pow(t, exponent) * b;
            }

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

                //shift _Hue with audiolink 4 band over time
                _ShiftedHue = _Hue + ((AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 1, _HueBand ) ).r % 1000000) / 1000000.0); 
                
                //shift _ColorStart with audiolink 4 band
                _ShiftedColorStart = saturate(_ColorStart + (AudioLinkData( ALPASS_FILTEREDAUDIOLINK  + uint2( 10, _ColorStartBand ) ).rrrr * .2));
                
                //shift _Value with audiolink 4 band
                _ShiftedValue = _Value + saturate(AudioLinkData( ALPASS_FILTEREDAUDIOLINK  + uint2( 10, _ValueBand ) ).r);

                //gradient stuff:
                float t = saturate(InvLerp(_ShiftedColorStart, _ColorEnd, v.uv.x));
                hsv.xyz = HSVtoRGB(_ShiftedHue, _Saturation, _ShiftedValue);
                o.color = ExponentialInterpolate(half4(0,0,0,0), hsv, t, _Exponent);
                
                //lines with waveform
                o.color.xyz -= saturate(AudioLinkLerpMultiline( ALPASS_WAVEFORM  + float2(o.uv.y * 1024 , _LinesBand ) ).rrr * 0.2);

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
