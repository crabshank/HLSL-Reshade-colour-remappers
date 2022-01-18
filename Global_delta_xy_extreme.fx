#include "ReShadeUI.fxh";

uniform int Mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform float2 satDeltaAmnt < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_max=1.0; ui_tooltip = "N.B.  colour include settings have no effect on this setting!";
> = float2(0,1);

uniform float2 redDeltaAmnt < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_max=1.0;
> =float2(0,1);

uniform float2 greenDeltaAmnt < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_max=1.0;
> =float2(0,1);

uniform float2 blueDeltaAmnt < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_max=1.0;
> =float2(0,1);

uniform float2 rgbDeltaAmnt < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_max=1.0; ui_tooltip = "N.B. avoid_grey and colour include settings have no effect on this setting!";
> = float2(0,1);

uniform float2 Y_DeltaAmnt < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_max=1.0; ui_tooltip = "N.B. avoid_grey and colour include settings have no effect on this setting!";
> = float2(0,1);
	
uniform bool avoid_grey <> = true;

uniform bool Red <ui_category="Select_color";> = true;
uniform bool Orange__Brown <ui_category="Select_color";> = true;
uniform bool Yellow <ui_category="Select_color";> = true;
uniform bool Chartreuse_Lime <ui_category="Select_color";> = true;
uniform bool Green <ui_category="Select_color";> = true;
uniform bool Spring_green <ui_category="Select_color";> = true;
uniform bool Cyan <ui_category="Select_color";> = true;
uniform bool Azure__Sky_blue <ui_category="Select_color";> = true;
uniform bool Blue <ui_category="Select_color";> = true;
uniform bool Violet__Purple <ui_category="Select_color";> = true;
uniform bool Magenta__Pink <ui_category="Select_color";> = true;
uniform bool Reddish_pink <ui_category="Select_color";> = true;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float delta(float color, float2 dlt){
color=lerp(dlt.x,dlt.y,color);
return color;
}

float2 avoid_grey_rgb(float2 DeltaAmnt, float greyMtrc, int act){
	float2 Delta=float2(
		(avoid_grey==true)?DeltaAmnt.x*greyMtrc:DeltaAmnt.x, 
		(avoid_grey==true)?lerp(1,DeltaAmnt.y,greyMtrc):DeltaAmnt.y
	);
	Delta=float2(
		(act==1)?Delta.x:rgbDeltaAmnt.x, 
		(act==1)?Delta.y:rgbDeltaAmnt.y
	);
	Delta=float2(
		max(Delta.x,rgbDeltaAmnt.x), 
		min(Delta.y,rgbDeltaAmnt.y)
	);
	return Delta;
}

float3 change(float3 c0, float3 h_sat_val){
	
float3 c0Lin=c0.rgb;
	
[branch]if (Linear==false){
	c0Lin=rgb2LinRGB(c0.rgb, Mode);
}	

float3 c0_og_Lin=c0Lin;

float3 c0_lin_xyY=LinRGB2xyY(c0Lin, Mode);
float3 c0_lin_hsv=rgb2hsv(c0Lin);
float3 c0_lin_hsv_adj=c0_lin_hsv;

int hue=floor(h_sat_val.x*3600);
int grey=(((c0.r==c0.g)&&(c0.g==c0.b))||(h_sat_val.y==0))?1:0;

int act=0;

if(((hue>=3525)||(((hue>=0) && (hue<75))&&(grey==0)))&&(Red==true)){
act=1;
}else if(((hue>=75) && (hue<375))&&(Orange__Brown==true)){
act=1;
}else if(((hue>=375) && (hue<675))&&(Yellow==true)){
act=1;
}else if(((hue>=675) && (hue<975))&&(Chartreuse_Lime==true)){
act=1;
}else if(((hue>=975) && (hue<1275))&&(Green==true)){
act=1;
}else if(((hue>=1275) && (hue<1575))&&(Spring_green==true)){
act=1;
}else if(((hue>=1575) && (hue<1875))&&(Cyan==true)){
act=1;
}else if(((hue>=1875) && (hue<2175))&&(Azure__Sky_blue==true)){
act=1;
}else if(((hue>=2175) && (hue<2475))&&(Blue==true)){
act=1;
}else if(((hue>=2475) && (hue<3075))&&(Violet__Purple==true)){
act=1;
}else if(((hue>=3075) && (hue<3375))&&(Magenta__Pink==true)){
act=1;
}else if(((hue>=3375) && (hue<3525))&&(Reddish_pink==true)){
act=1;
}
float3 c0_lin_post_sat=c0Lin;

[branch]if (satDeltaAmnt.x > 0 || satDeltaAmnt.y < 1){
	c0_lin_hsv_adj.y=delta(c0_lin_hsv_adj.y, satDeltaAmnt);
	float3 c0_lin_hsv_adj_rgb=hsv2rgb(c0_lin_hsv_adj);
	float3 c0_lin_hsv_adj_xyY=LinRGB2xyY(c0_lin_hsv_adj_rgb, Mode);

	float3 c0_lin_adj_sat_rgb=xyY2LinRGB(float3(c0_lin_hsv_adj_xyY.xy,c0_lin_xyY.z), Mode);

	c0_lin_post_sat=xyY2LinRGB(float3(c0_lin_hsv_adj_xyY.xy,c0_lin_xyY.z), Mode);
}

float greyMtrc=lerp(min(h_sat_val.y,h_sat_val.y*h_sat_val.z),h_sat_val.y,h_sat_val.z);

float2 rDelta=avoid_grey_rgb(redDeltaAmnt,greyMtrc, act);
float2 gDelta=avoid_grey_rgb(greenDeltaAmnt,greyMtrc, act);
float2 bDelta=avoid_grey_rgb(blueDeltaAmnt,greyMtrc, act);

float3 c0_lin_post_rgb=float3(
	delta(c0_lin_post_sat.r, rDelta), 
	delta(c0_lin_post_sat.g, gDelta), 
	delta(c0_lin_post_sat.b, bDelta)
);

float3 rgb_lin_out=c0_lin_post_rgb;

[branch]if (Y_DeltaAmnt.x > 0 || Y_DeltaAmnt.y < 1){
	float3 c0_lin_post_rgb_xyY=LinRGB2xyY(c0_lin_post_rgb, Mode);
	float3 c0_lin_post_rgb_xyY_adj_Y=c0_lin_post_rgb_xyY;
	c0_lin_post_rgb_xyY_adj_Y.z=delta(c0_lin_post_rgb_xyY.z, Y_DeltaAmnt);
	rgb_lin_out=xyY2LinRGB(c0_lin_post_rgb_xyY_adj_Y, Mode);
}

float3 rgb_out=rgb_lin_out;

[branch]if(Linear==false){
	rgb_out=LinRGB2rgb(rgb_lin_out, Mode);
}

return rgb_out;

}

float4 deltaxyExtremePass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float3 c0_hsv=rgb2hsv(c0.rgb);

float4 c1=c0;
c1.rgb=change(c0.rgb, c0_hsv);

return c1;

}

technique Global_delta_xy_extreme
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = deltaxyExtremePass;
	}
}