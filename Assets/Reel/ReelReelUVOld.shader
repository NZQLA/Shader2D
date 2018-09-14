// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// 卷轴收起Shader，以卷动的方式将一个平整的片卷起来，只有一个卷，
// 处理方式：UV变换
// 卷动部分随着时间向右推移，渲染分3种情况
//  1. 卷动部分后面的剪掉，步渲染
//  2. 卷动所在的部分，对UV进行处理，并使用指定的背面纹理进行渲染
//  3. 卷动前面的部分，不做任何处理，照常渲染


Shader "Custom/Reel"
{
    Properties
    {
        _MainTex ("Base (RGB), Alpha (A)", 2D) = "black" {}
        _BackTex ("Base (RGB), Alpha (A)", 2D) = "black" {}

        _Color("Color", Color) = (1,1,1,1)
        _AngleMaxMax("AngleMax", Range(0, 360)) = 360
        _Ridus("ridus 卷轴半径", Range(0, 0.159)) = 0.015
        _TimeScale("TimeScale",Range(0,1)) = 0.5
    }
    
    SubShader
    {
        LOD 200

        Tags
        {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
        }
        
        Pass
        {
            Cull Back
            Lighting Off
            Fog { Mode Off }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag            
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BackTex;
            float4 _BackTex_ST;

            float4 _Color;
            float _AngleMaxMax;
            float _Ridus;
            float _TimeScale;

            float _cur;
            float _left;
            float _right;
            float _lenMax ;
            bool _isInRange;
            float _AngleCur;

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                fixed4 color : COLOR;
            };
    
            struct v2f
            {
                float4 vertex : SV_POSITION;
                half2 texcoord : TEXCOORD0;
                fixed4 color : COLOR;
            };
    


            // 用于计算卷动部分的边界(这里指的是左右边界)
            void CaculateBorder()
            {
                _lenMax = _AngleMaxMax*0.0174532924*_Ridus;
                float timeCur = _Time.y*_TimeScale;;
                _left = timeCur;
                _right = _left + _lenMax;
            }

            // 计算卷动部分的UV
            float2 CaculateReelPartUV(half2 uv)
            {
                if(uv.x>=_left&&uv.x<=_right)
                {
                    // _isInRange = true;
                    //计算当前uv应该旋转的角度
                    _AngleCur = (uv.x -_left)/_lenMax;
                
                    float2 centerUV;
                    centerUV.x = _left + _Ridus;
                    centerUV.y = uv.y + _Ridus;
                    // centerUV.y =  _Ridus;

                    fixed2 uvRota ;
                    uvRota.x = centerUV.x - _Ridus *sin(_AngleCur);
                    uvRota.y = centerUV.y - _Ridus *cos(_AngleCur);
                    return uvRota;
                }
                return uv;
            }

            float ColorInRange(half2 uv)
            {
                float mid  = (_left + _right)*0.5;
                return  1 -  abs(uv.x - mid)/(_Ridus*0.5);
            }


            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = v.texcoord;
                o.color = v.color;
                return o;
            }
            
            
            
            float4 frag (v2f i) : COLOR
            {
                CaculateBorder();
                clip(i.texcoord.x - _left);
                float4 col;
                // 对于在卷动的部分使用背面纹理渲染
                if(i.texcoord.x>=_left&&i.texcoord.x<=_right)
                {
                    i.texcoord = CaculateReelPartUV(i.texcoord);
                    col = tex2D(_BackTex, i.texcoord);
                }
                // 对于未被卷动的部分不做任何处理
                else
                {
                    col = tex2D(_MainTex, i.texcoord);
                }

                // // 对卷动部分进行颜色叠加处理
                // if(i.texcoord.x>=_left&&i.texcoord.x<=_right)
                // {
                //     col += _Color*ColorInRange(i.texcoord);
                // }
                return col;
            }
            
            ENDCG
        }
    }

}
