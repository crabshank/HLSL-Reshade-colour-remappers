#include "ReShadeUI.fxh"


uniform float Value < __UNIFORM_DRAG_FLOAT1
	ui_min = 0; ui_max = 1;  ui_tooltip = "Disabled if =0";
> = 0.63;

#include "ReShade.fxh"

#define PI acos(-1)

float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
 
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}


float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
//Source: http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl



float4 Saturated_hues_Pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float4 c1=c0;

float3 c1_hsv=rgb2hsv(c0.rgb);

c1_hsv.y=1;
c1_hsv.z=Value;

c1.rgb=hsv2rgb(c1_hsv);

return c1;

}

technique Saturated_hues
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Saturated_hues_Pass;
	}
}