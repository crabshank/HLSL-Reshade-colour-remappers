#include "ReShadeUI.fxh";

uniform int Mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0Orignal NTSC D65\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform float satDeltaAmnt < __UNIFORM_DRAG_FLOAT1
	ui_min = -1.0; ui_max=1.0; ui_tooltip = "N.B.  colour include settings have no effect on this setting!";
> = 0;

uniform float redDeltaAmnt < __UNIFORM_DRAG_FLOAT1
	ui_min = -1.0; ui_max=1.0;
> = 0;

uniform float greenDeltaAmnt < __UNIFORM_DRAG_FLOAT1
	ui_min = -1.0; ui_max=1.0;
> = 0;

uniform float blueDeltaAmnt < __UNIFORM_DRAG_FLOAT1
	ui_min = -1.0; ui_max=1.0;
> = 0;

uniform float rgbDeltaAmnt < __UNIFORM_DRAG_FLOAT1
	ui_min = -1.0; ui_max=1.0; ui_tooltip = "N.B. avoid_grey and colour include settings have no effect on this setting!";
> = 0;

uniform float Y_DeltaAmnt < __UNIFORM_DRAG_FLOAT1
	ui_min = -1.0; ui_max=1.0; ui_tooltip = "N.B. avoid_grey and colour include settings have no effect on this setting!";
> = 0;
	
uniform bool avoid_grey <> = true;

uniform bool avoid_light <> = false;

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

float delta(float color, float dlt){
[flatten]if(dlt==1){
color=1;
}else if(dlt==-1){
color=0;
}else if(color==0){
color=(dlt<0)?color:dlt;
}else if(color==1){
color=(dlt<0)?1+dlt:color;
}else{
dlt=-0.5*dlt+0.5;
float relx=color/dlt;
float relxInv=(1-color)/(1-dlt);

float newyLow=(1-dlt)*relx;
float newyHi=-dlt*relxInv+1;

color=(color<=dlt)?newyLow:newyHi;
}
return color;
}

float4 change(float4 c0, float3 h_sat_val){
	
float3 c0Lin=c0.rgb;
	
[branch]if (Linear==false){
c0Lin=rgb2LinRGB(c0.rgb, Mode);
}	

float3 c0_og_Lin=c0Lin;

[branch]if((redDeltaAmnt!=0)||(greenDeltaAmnt!=0)||(blueDeltaAmnt!=0)){

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

if (act==1){

c0Lin.r=(redDeltaAmnt==0)?c0Lin.r:delta(c0Lin.r,redDeltaAmnt);

c0Lin.g=(greenDeltaAmnt==0)?c0Lin.g:delta(c0Lin.g,greenDeltaAmnt);

c0Lin.b=(blueDeltaAmnt==0)?c0Lin.b:delta(c0Lin.b,blueDeltaAmnt);

float greyMtrc=lerp(min(h_sat_val.y,h_sat_val.y*h_sat_val.z),h_sat_val.y,h_sat_val.z);
c0Lin.rgb=(avoid_grey==true)?lerp(c0_og_Lin.rgb, c0Lin.rgb,greyMtrc):c0Lin.rgb;

}

}

float3 nw_hsv=rgb2hsv(c0Lin);
[branch]if(satDeltaAmnt!=0){

float nwSat=delta(nw_hsv.y,satDeltaAmnt);
float greyMtrc=lerp(min(nw_hsv.y,nw_hsv.y*nw_hsv.z),nw_hsv.y,nw_hsv.z);
nw_hsv.y=(avoid_grey==true)?lerp(nw_hsv.y,nwSat,greyMtrc):nwSat;

c0Lin=hsv2rgb(nw_hsv);
}

[branch]if(rgbDeltaAmnt!=0){
c0Lin=float3(delta(c0Lin.r,rgbDeltaAmnt),delta(c0Lin.g,rgbDeltaAmnt),delta(c0Lin.b,rgbDeltaAmnt));
}

float og_Y=LinRGB2Y(c0_og_Lin,Mode);

c0Lin.rgb=(avoid_light==true)?lerp(c0Lin.rgb,c0_og_Lin.rgb,og_Y):c0Lin.rgb;

float nw_Y=(Y_DeltaAmnt==0)?og_Y:delta(og_Y,Y_DeltaAmnt);

float3 nw_xyY= LinRGB2xyY(c0Lin.rgb,Mode);

[branch]if (Linear==true){
c0.rgb=xyY2LinRGB(float3(nw_xyY.xy,nw_Y),Mode);
}else{
c0.rgb=xyY2rgb(float3(nw_xyY.xy,nw_Y),Mode);
}

return c0;

}

float4 deltaxy2Pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float3 c0_hsv=rgb2hsv(c0.rgb);

float4 c1=change(c0, c0_hsv);


return c1;

}

technique Global_delta2_xy
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = deltaxy2Pass;
	}
}