Shader "Custom/UnlitGradients"
{
    Properties
    {   
        [Header(Colors)]
        _Lightness("Lightness: ", range(0,1)) = 0.5
        _Chroma("Chroma: ", range(0,1)) = 1
        _Hue("Hue: ", range(0,1)) = 1
           
        [Header(Gradient Controls)]
        _ColorStart("ColorStart: ", Range(0,1)) = 0.5
        _ColorEnd("ColorEnd: ", float) = 0.5
        _Exponent("Exponent: ", float) = 1

        [Header(Lines)]
        [ToggleUI] _LinesEnabled ("Lines Enabled: ", int) = 1
        _LinesGain ("Lines Gain: ", float) = 1

        [Header(Audiolink Bands)]
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _ColorStartBand("ColorStartBand: ", int) = 0
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _HueBand("HueBand: ", int) = 1
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _ChromaBand("ChromaBand: ", int) = 2
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _LinesBand("LinesBand: ", int) = 3

        [Space(20)] _AudioLink ("AudioLink Texture", 2D) = "black" {}
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
            #include "Lighting.cginc"
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

            struct OKLAB //OKLAB color space
            {
                float L; //Lightness
                float C; //Chroma
                float H; //Hue
                float a; //GreenRed
                float b; //BlueYellow
            };

            float _Chroma;
            float _Lightness;
            float _Hue;
            float _GreenRed;
            float _BlueYellow;
            

            float _ColorStart;
            float _ColorEnd;
            float _Exponent;

            float _ShiftedColorStart;
            float _ShiftedHue;
            float _ShiftedValue;

            int _ColorStartBand;
            int _HueBand;
            int _ChromaBand;
            int _LinesBand;

            float _LinesGain;
            int _LinesEnabled;

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

            //OKLAB to sRGB conversion from: https://bottosson.github.io/posts/oklab/
            float4 OKLABtoRGB(float L, float A, float B)
            {
                float y = (L + 0.3963377774 * A + 0.2158037573 * B);
                float x = (L - 0.1055613458 * A - 0.0638541728 * B);
                float z = (L - 0.0894841775 * A - 1.2914855480 * B);

                float r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z;
                float g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z;
                float b = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z;
                
                r = r <= 0.0031308 ? 12.92 * r : 1.055 * pow(r, 1 / 2.4) - 0.055;
                g = g <= 0.0031308 ? 12.92 * g : 1.055 * pow(g, 1 / 2.4) - 0.055;
                b = b <= 0.0031308 ? 12.92 * b : 1.055 * pow(b, 1 / 2.4) - 0.055;

                return float4(r, g, b, 1);
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                //shift _Hue with audiolink band over time
                _Hue = (AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY  + uint2( 1, _HueBand ) ) % 1000000.) / 1000000.; 

                //shift _Chroma with audiolink band
                _Chroma -= AudioLinkData( ALPASS_FILTEREDAUDIOLINK  + uint2( 5, _ChromaBand ) );
                
                //shift _ColorStart with audiolink band
                _ColorStart -= AudioLinkData( ALPASS_FILTEREDAUDIOLINK  + uint2( 1, _ColorStartBand ) );
                
                //convert from LCH to Lab color space
                _GreenRed = _Chroma * cos(_Hue * 6.28318530718);
                _BlueYellow = _Chroma * sin(_Hue * 6.28318530718);

                //gradient stuff:
                float t = InvLerp(_ColorStart, _ColorEnd, v.uv.x);
                o.color = ExponentialInterpolate(half4(0,0,0,0), OKLABtoRGB(_Lightness, _GreenRed, _BlueYellow), t, _Exponent);
                
                //lines with waveform
                //o.color.xyz -= saturate(AudioLinkLerpMultiline( ALPASS_WAVEFORM  + float2(o.uv.y * 512 , _LinesBand ) ).rrr * 0.2);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if (_LinesEnabled)
                {
                float Sample = saturate(AudioLinkLerpMultiline( ALPASS_WAVEFORM  + float2(i.uv.y * 128., _LinesBand ) ).r * _LinesGain);
                half Line = clamp( 1 - (.8 * abs( 1 - (Sample * .2) + (i.uv.x * .9))), 0, 1 );
                i.color.xyz -= Line;
                }

                return i.color;
            }
            ENDCG
        }
    }
}
