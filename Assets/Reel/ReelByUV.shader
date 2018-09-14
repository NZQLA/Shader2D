// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// 卷轴收起Shader，以卷动的方式将一个平整的片卷起来，只有一个卷，
//可配置卷的角度(0,360)
Shader "Custom/ReelUV"
{
    Properties
    {
        _MainTex ("Base (RGB), Alpha (A)", 2D) = "black" {}
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
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
        }
        
        Pass
        {
            Cull off
            Lighting Off
            ZWrite Off
            Fog { Mode Off }
            Offset -1, -1
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag            
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
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
    



            void CaculateBorder()
            {
                // 计算卷轴的长度(指的是卷曲部分) = 2 PI*r *(指定的最大角度/2PI) ，需要处理弧度问题
                _lenMax = _AngleMaxMax*0.0174532924*_Ridus;

                //这里直接将当前时间作为卷轴左侧，右侧 = 左侧 + 卷轴长度(其实是UV的水平长度，范围0~1)
                float timeCur = _Time.y*_TimeScale;;
                _left = timeCur;
                _right = _left + _lenMax;
            }

            float2 CaculateCurUV(half2 uv)
            {
                if(uv.x>=_left&&uv.x<=_right)
                {
                    //计算当前uv应该旋转的角度
                    _AngleCur = abs(uv.x -_left)/_lenMax*_AngleMaxMax*0.0174532924;
                
                    // 计算圆形的UV值
                    float2 centerUV;
                    centerUV.x = _left + UNITY_TWO_PI*_Ridus;
                    centerUV.y = uv.y;

                    // centerUV.x = _left + _Ridus;
                    // centerUV.y = uv.y + _Ridus;

                    // 对当前的UV进行旋转处理
                    fixed2 uvRota ;
                    uvRota.x = centerUV.x - _Ridus *sin(_AngleCur);
                    uvRota.y = centerUV.y - _Ridus *cos(_AngleCur);

                    // 方案一
                    // uvRota.x = centerUV.x - _Ridus *sin(_AngleCur);
                    // uvRota.y = centerUV.y - _Ridus *cos(_AngleCur);
                    return uvRota;
                }
                return uv;
            }

            //  弃用
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
            
            
            // 将卷 左侧的剪掉，不渲染
           //  卷右侧，维持原样
            float4 frag (v2f i) : COLOR
            {
                CaculateBorder();
                clip(i.texcoord.x - _left);
                i.texcoord = CaculateCurUV(i.texcoord);
                float4 col = tex2D(_MainTex, i.texcoord);

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
