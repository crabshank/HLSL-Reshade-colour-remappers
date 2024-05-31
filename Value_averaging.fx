#include "ReShadeUI.fxh"

uniform int dxy < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 10;
	ui_tooltip = "No. of adjacent pixels to include in the sample.";
> = 3;

uniform float lerper  < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 1;
> = 0.3;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float4 PS_Averaging(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target{

	float4 c0=tex2D(ReShade::BackBuffer, texcoord);
	float3 c0_hsv=rgb2hsv(c0.rgb);

	int x=0;
	int y=0;
	float count=0;
	float accm=0;

	for (x=-1*dxy; x<=dxy; x+=1){
	for (y=-1*dxy; y<=dxy; y+=1){
	
		float4 current=tex2Dlod(ReShade::BackBuffer, float4(texcoord.x+float(x)*BUFFER_RCP_WIDTH, texcoord.y+float(y)*BUFFER_RCP_HEIGHT, 0, 0));
		float3 currMax=max(current.r,max(current.g, current.b));
		accm+=currMax;
		count+=1.0;
	}
	}
	
	float nw_v=accm/count;
	float lrp_v=lerp(c0_hsv.z,nw_v,lerper);
	float3 nw_hsv=float3(c0_hsv.xy,lrp_v);
	float3 nw_rgb=hsv2rgb(nw_hsv);
	float4 c1=float4(nw_rgb,c0.w);
	return c1;

}

technique Value_averaging {
	pass Averaging {
		VertexShader=PostProcessVS;
		PixelShader=PS_Averaging;
	}
}
