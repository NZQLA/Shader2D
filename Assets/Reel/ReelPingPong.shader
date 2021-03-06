/*
* 卷轴收起Shader，以卷动的方式将一个平整的片卷起来，只有一个卷，
* 处理方式：UV变换
* 卷动部分随着时间向右推移，渲染分3种情况
*  1. 卷动部分后面的剪掉，步渲染
*  2. 卷动所在的部分，对UV进行处理，并使用指定的背面纹理进行渲染
*  3. 卷动前面的部分，不做任何处理，照常渲染
* 支持铺开卷轴和收起卷轴，取决于开关[_InverseToggel]
* 正常使用这个shader需要配置3个变量
*   1. [_ActionSwitch] 设置为1，才可以开启卷轴动效
*   2. [_TimeStart] 每次开启特效是都需要将目前时间(使用Time.timeSinceLevelLoad)赋值
*   3. [_InverseToggel] 0，收起卷轴；1，铺开卷轴
*/


Shader "Custom/ReelPingPong"
{
    Properties
    {
        _MainTex ("Base (RGB), Alpha (A)", 2D) = "black" {}
        _BackTex ("Base (RGB), Alpha (A)", 2D) = "black" {}

        _AngleMaxMax("AngleMax", Range(0, 360)) = 360
        _Ridus("ridus 卷轴半径", Range(0, 0.159)) = 0.015
        _TimeScale("TimeScale",Range(0,1)) = 0.5
        
        _TimeStart("TimeStart",Float) = 0
         _ActionSwitch("ActionSwitch",Float) = 0
        [Toggle] _InverseToggel("InverseToggel",Float) = 0
    
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

            float _AngleMaxMax;
            float _Ridus;
            float _TimeScale;
            float _InverseToggel;
            float _TimeStart;
            float _ActionSwitch;

            float _cur;
            float _from;
            float _to;
            float _min;
            float _max;
            float _lenMax ;
            bool _isInRange;
            float _AngleCur;
            float _halfPerimeter;

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
    
            void Ready()
            {
                if(_InverseToggel)
                {
                    
                }                
            }

            // 用于计算卷动部分的边界(这里指的是左右边界)
            void CaculateBorder()
            {
                _lenMax = _AngleMaxMax*0.0174532924*_Ridus;
                _halfPerimeter = UNITY_PI*_Ridus;
                
                // float timeCur = clamp( _Time.y*_TimeScale,0,1);
                float timeCur = (_Time.y - _TimeStart)*_TimeScale;
                
                if(_InverseToggel)
                {
                    _from = clamp( 1 - timeCur, 0, 1);
                    _to = clamp( _from - _lenMax, 0 , 1);
                    _min = _to;
                    _max = _from;
                }
                else
                {
                    _from = clamp( timeCur, 0, 1);
                    _to =clamp( _from + _lenMax,0,1);
                    _min = _from;
                    _max = _to;
                }
            }

            // 计算卷动部分的UV
            float2 CaculateReelPartUV(half2 uv)
            {
                fixed2 uvRota ;
                float2 centerUV;
                //计算当前uv应该旋转的角度
                _AngleCur =abs((uv.x -_from)/_lenMax);
                centerUV.x = _from + _Ridus;
                centerUV.y = uv.y + _Ridus;

                uvRota.x = centerUV.x - _Ridus *sin(_AngleCur);
                uvRota.y = centerUV.y - _Ridus *cos(_AngleCur);
                return uvRota;
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
                if(!_ActionSwitch)
                {
                    return tex2D(_MainTex, i.texcoord);
                }

                CaculateBorder();
                clip(i.texcoord.x -_min);

                float4 col;
                // 对于在卷动的部分使用背面纹理渲染
                if(i.texcoord.x>=_min&&i.texcoord.x<=_max)
                {
                    i.texcoord = CaculateReelPartUV(i.texcoord);
                    col = tex2D(_BackTex, i.texcoord);
                }
                // 对于未被卷动的部分不做任何处理
                else
                {
                    col = tex2D(_MainTex, i.texcoord);
                }

                // _ActionSwitch =1- _max;
                return col;
            }
            
            ENDCG
        }
    }

}
