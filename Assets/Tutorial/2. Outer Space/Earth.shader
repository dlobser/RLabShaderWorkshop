Shader "Unlit/Earth"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Data ("Data", vector) = (0,0,0,0)
        _Light("Light",vector) = (0,1,0)
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            //#include "noise.cginc"
            #include "noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float2 uv : TEXCOORD0;
                float4 pos : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 pos : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Data;
            float3 _Light;
            
            //float3x3 rotationMatrix(float3 axis, float angle)
            //{
            //    axis = normalize(axis);
            //    float s = sin(angle);
            //    float c = cos(angle);
            //    float oc = 1.0 - c;

            //    return float3x3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
            //        oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
            //        oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c);
            //}
            
            float3 grad(float3 p,float o){
                float r = snoise(p);
                return float3(
                    (snoise(p+float3(o,0,0))-r)/o,
                    (snoise(p+float3(0,o,0))-r)/o,
                    (snoise(p+float3(0,0,o))-r)/o
                    );
            }
            
            //float3 grad3(float3 orig_pos, float o){
            //    float3 dx = float3(0.01, 0.0, 0.0);
            //    float3 dy = dx.yxy;
            //    float3 dz = dx.yyx;
            //    float3 n =  normalize(orig_pos);
            //    float3 nx = normalize(orig_pos + dx);
            //    float3 ny = normalize(orig_pos + dy);
            //    float3 nz = normalize(orig_pos + dz);
            //    float3 normal;
            //    normal.x = (orig_pos + snoise(orig_pos)*n) - (orig_pos + dy + snoise(orig_pos + dy)*nx);
            //    normal.y = (orig_pos + snoise(orig_pos)*n) - (orig_pos + dy + snoise(orig_pos + dy)*ny); 
            //    normal.z = (orig_pos + snoise(orig_pos)*n) - (orig_pos + dz + snoise(orig_pos + dz)*nz);
            //    return normal;
            //}
            
            v2f vert (appdata v)
            {
                v2f o;
                float n = pow(max(0,snoise(v.vertex*_Data.x)-_Data.y),2);//sin(v.uv.x*30)*.1;
                
                float2 e = float2(0.01, 0.0);
               
                float3 noise = normalize(grad(v.vertex*_Data.x,.001))*.5;
                float3 on = normalize(v.normal-noise);
                
                o.normal = v.normal;//cross(v.tangent,binormal);//float3(y+1,x+1,0)*.3;// float3(x,y,0);      
                o.tangent = mul (unity_ObjectToWorld, v.normal).xyz;

                o.vertex = UnityObjectToClipPos(v.vertex+v.normal*n*_Data.z);
                o.pos = v.vertex;
                float3 zNormal = COMPUTE_VIEW_NORMAL;
                o.pos.w = zNormal.z;               

                //o.normal = v.normal;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            
            
            
            fixed4 frag (v2f i) : SV_Target
            {
         
                float x = snoise(i.pos * _Data.x )-_Data.y;
                float x2 = snoise(i.pos * _Data.x * 22 )-_Data.y;
                float x3 = snoise(i.pos * _Data.x * 8 + _Time.y )-_Data.y;
                float x4 = snoise(100 + i.pos * _Data.x );

                fixed4 col = tex2D(_MainTex, i.uv);

                float3 noise = normalize(grad(i.pos*_Data.x,.001)*.2)*min(1,_Data.z*2);
                noise = mul (unity_ObjectToWorld,noise);
                float3 noise2 = normalize(grad(i.pos*42,.001))*.051;
                noise2 = mul (unity_ObjectToWorld,noise2);
                
                //float z = sin(snoise(i.pos+noise ));

                float3 on = lerp(
                i.tangent+noise2*.1,
                normalize(i.tangent-noise+lerp(noise2,float3(0,0,0),smoothstep(1.5,1.6,x+x2*.05+1))),
                smoothstep(_Data.y,_Data.y+.1,x)
                );
                float lighting = dot(on,normalize(_Light));
                
                float3 water = lerp(float3(0,.5,1),float3(0,.4,.9),x3+1);
                float3 land = lerp(float3(.3,1,.1),float3(.8,.9,0),(x4+1)*.5);
                float3 snow = float3 (1,1,1);
                float3 rim = float3(.5,.8,1);
                
                float3 waterLand = lerp(water,land,smoothstep(.45,.51,x+x3*.05+1));
                float3 waterLandSnow = lerp(waterLand,snow,smoothstep(1.5,1.6,x+x2*.05+1));
                float3 withRim = lerp(waterLandSnow,rim,pow(1-i.pos.w,2)*2);
                float3 oRim = pow((1-i.pos.w),3)*rim;
                return pow((max(0,min(1,lighting+.05))),1.5) * withRim.xyzx + oRim.xyzx;//smoothstep(0,.02,x);//nNormal.xyzx;//mul(i.normal,rz).xyzx;
            }
            ENDCG
        }
        
        Tags { "RenderType"="Transparent""Queue"="Transparent" }
        LOD 200
        Blend OneMinusDstColor One
        Cull Front
        ZWrite Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex+v.normal);
                o.uv = v.uv;
                o.normal = COMPUTE_VIEW_NORMAL;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float o = max(0,.5-i.normal.z);
                return pow(o,4)*float4(0,.5,1,0)*.5;
            }
            ENDCG
        }
        
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            //#include "noise.cginc"
            #include "noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 pos : COLOR;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 vertex : SV_POSITION;
                float4 pos : COLOR;
                float3 tangent : TANGENT;

            };

            float4 _Data;
            float3 _Light;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex+v.normal*.05);
                o.pos = v.vertex;
                float3 zNormal = COMPUTE_VIEW_NORMAL;
                o.pos.w = zNormal.z; 
                o.tangent = mul (unity_ObjectToWorld, v.normal).xyz;
              
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float x = snoise(i.pos * _Data.x )-_Data.y+-.5;
                x *= max(0,snoise(_Time.x+i.pos * _Data.x*3 )-_Data.y+snoise(_Time.x+i.pos * _Data.x*.5 )-.5);
                clip((x*-1)-.05);
                float l = dot(i.tangent,normalize (_Light))+.3;

                return float4(l*.6,l*.7,l,.8);
            }
            ENDCG
        }
        
        
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            //#include "noise.cginc"
            #include "noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 pos : COLOR;
                float3 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 vertex : SV_POSITION;
                float4 pos : COLOR;
                float3 tangent : TANGENT;

            };

            float4 _Data;
            float3 _Light;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex+v.normal*.065);
                o.pos = v.vertex;
                float3 zNormal = COMPUTE_VIEW_NORMAL;
                o.pos.w = zNormal.z; 
                o.tangent = mul (unity_ObjectToWorld, v.normal).xyz;
              
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float x = snoise(i.pos * _Data.x )-_Data.y-.5;
                x *= max(0,snoise(_Time.x+i.pos * _Data.x*3 )-_Data.y+snoise(_Time.x+i.pos * _Data.x*.5 )-.5);

                clip((x*-1)-.1);
                float l = dot(i.tangent,normalize (_Light))+.4;

                return float4(l,l,l,1);
            }
            ENDCG
        }
        
    }
    
}
