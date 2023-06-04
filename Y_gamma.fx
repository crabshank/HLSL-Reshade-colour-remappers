#include "ReShadeUI.fxh"

uniform int Mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0Orignal NTSC D65\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform float Y_Gamma_Lo < __UNIFORM_DRAG_FLOAT1
	ui_min = -20; ui_max=20; ui_tooltip = "N.B. avoid_grey and colour include settings have no effect on this setting!";
> = 0.9;

uniform float Y_Gamma_Hi < __UNIFORM_DRAG_FLOAT1
	ui_min = -20; ui_max=20; ui_tooltip = "N.B. avoid_grey and colour include settings have no effect on this setting!";
> =0.2;

uniform int Y_Gamma_Mode <__UNIFORM_COMBO_INT1
    ui_items = "Brighten only\0Darken only\0No bias\0";
	> = 0;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float4 change(float4 c0,float Y_Gamma_lo, float Y_Gamma_hi){

float3 c0Lin=c0.rgb;
	
[branch]if (Linear==false){
c0Lin=rgb2LinRGB(c0.rgb, Mode);
}

float3 c0_og_Lin=c0Lin;

float3 og_xyY=LinRGB2xyY(c0_og_Lin,Mode);

float nw_Y=(Y_Gamma_lo==1 && Y_Gamma_hi==1)?og_xyY.z:lerp(pow(og_xyY.z,Y_Gamma_lo),pow(og_xyY.z,Y_Gamma_hi),og_xyY.z);

nw_Y=(nw_Y<og_xyY.z)?og_xyY.z:nw_Y;

[flatten]if(Y_Gamma_Mode==0){
nw_Y=(nw_Y>og_xyY.z)?nw_Y:og_xyY.z;
}else if(Y_Gamma_Mode==1){
nw_Y=(nw_Y<og_xyY.z)?nw_Y:og_xyY.z;
}

float3 nw_xyY= LinRGB2xyY(c0Lin.rgb,Mode);

[branch]if (Linear==true){
c0.rgb=xyY2LinRGB(float3(nw_xyY.xy,nw_Y),Mode);
}else{
c0.rgb=xyY2rgb(float3(nw_xyY.xy,nw_Y),Mode);
}

return c0;

}

float4 Y_gamma_pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float3 c0_hsv=rgb2hsv(c0.rgb);

float xCoord_Pos;
float yCoord_Pos;
float Y_Gamma_lo=Y_Gamma_Lo;
float Y_Gamma_hi=Y_Gamma_Hi;

float4 c1=change(c0,Y_Gamma_lo,Y_Gamma_hi);

return c1;

}

technique Y_gamma
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Y_gamma_pass;
	}
}
