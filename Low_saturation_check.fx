#include "ReShadeUI.fxh"

uniform int Grey_colour < __UNIFORM_COMBO_INT1
    ui_items = "Black\0Mid_grey\0White\0";
> = 0;

uniform int Metric < __UNIFORM_COMBO_INT1
    ui_items = "saturation\0min(chroma,saturation)\0";
> = 0;

uniform float Greyness < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 1;
		ui_tooltip = "Blacken/whiten pixels with Metric<=Greyness";
> = 0.015;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float4 lowSatPass(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{

float4 c0 = tex2D(ReShade::BackBuffer, texcoord);
float mx=max(c0.r,max(c0.g,c0.b));
float mn=min(c0.r,min(c0.g,c0.b));
float chr=mx-mn;
float sat=(mx==0)?0:(chr)/mx;
float greyOut=0;

[flatten]if(Grey_colour==2){
					greyOut=1;
				}else if(Grey_colour==1){
					greyOut=0.5;
				}

[flatten]if(Metric==1){
	c0.rgb=(min(chr,sat)<=Greyness)?greyOut:c0.rgb;
}else{
	c0.rgb=(sat<=Greyness)?greyOut:c0.rgb;
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
