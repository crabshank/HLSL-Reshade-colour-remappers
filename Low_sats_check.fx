#include "ReShadeUI.fxh"

uniform float Sat_lo < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 1;
		ui_tooltip = "Blacken pixels with saturation < Sat_lo";
> = 0.03;

uniform float Sat_hi < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 1;
		ui_tooltip = "Make pixels with saturation >=Sat_lo and <Sat_hi grey";
> = 0.17;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float4 lowSatsPass(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{

float4 c0 = tex2D(ReShade::BackBuffer, texcoord);
float mx=max(c0.r,max(c0.g,c0.b));
float mn=min(c0.r,min(c0.g,c0.b));
float chr=mx-mn;
float sat=(mx==0)?0:(chr)/mx;

c0.rgb=(sat<Sat_lo)?0:((sat<Sat_hi)?0.5:c0.rgb);

return c0;
}

technique Low_sats_check
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = lowSatsPass;
	}
}
