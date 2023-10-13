Shader "Custom/WibblyLines"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Audiolink Bands)]
        [Enum(Bass,0,LowMid,1,HighMid,2,Trebble,3)] _LinesBand("LinesBand: ", int) = 1
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _LinesBand;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float chrono = (AudioLinkDecodeDataAsUInt( ALPASS_CHRONOTENSITY + float2(0, _LinesBand) ) % 1000000) / 1000000.;
                float history = AudioLinkLerp( ALPASS_AUDIOLINK + float2(20, 2));
                float Sample = AudioLinkLerpMultiline( ALPASS_WAVEFORM + float2( 128. * i.uv.x, 1 ) ).r; 

                float Line = clamp( 1 - 20 * abs( .2 + (Sample * history) - (i.uv.y * 2)), 0, 0.5 );

                return float4(Line * chrono, Line * history, Line * 1 - history, 1);
            }
            ENDCG
        }
    }
}
