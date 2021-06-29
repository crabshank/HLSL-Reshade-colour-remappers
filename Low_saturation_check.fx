#include "ReShadeUI.fxh"

uniform bool Turn_black <> = true;

uniform float Saturation < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 1;
		ui_tooltip = "Blacken/whiten pixels <=Saturation";
> = 0.015;

#include "ReShade.fxh"

float4 lowSatPass(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{

float4 c0 = tex2D(ReShade::BackBuffer, texcoord);
float mx=max(c0.r,max(c0.g,c0.b));
float mn=min(c0.r,min(c0.g,c0.b));
float sat=(mx==0)?0:(mx-mn)/mx;
[flatten]if(sat<=Saturation){
c0.rgb=(Turn_black==true)?0:1;
}
return c0;

}

technique Low_saturation_check
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = lowSatPass;
	}
}
