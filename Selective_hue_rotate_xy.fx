#include "ReShadeUI.fxh";

uniform int Mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0Orignal NTSC D65\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform bool Red = true;
uniform float Red_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Orange__Brown = true;
uniform float Orange__Brown_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Yellow = true;
uniform float Yellow_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Chartreuse_Lime = true;
uniform float Chartreuse_Lime_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Green = true;
uniform float Green_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Spring_green = true;
uniform float Spring_green_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Cyan = true;
uniform float Cyan_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Azure__Sky_blue = true;
uniform float Azure__Sky_blue_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Blue = true;
uniform float Blue_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Violet__Purple = true;
uniform float Violet__Purple_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Magenta__Pink = true;
uniform float Magenta__Pink_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;
uniform bool Reddish_pink = true;
uniform float Reddish_pink_Rotate < __UNIFORM_SLIDER_FLOAT1
	ui_min = -180.0; ui_max=180.0;
> = 0;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float hue_rotate(float hue,float rot){rot/=360.0;float r=hue+rot;[flatten]if(r<0){return 1+r;}else if(r>1){return r-1;}else{return r;}} 

float4 selHueRotPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	
float4 c0=tex2D(ReShade::BackBuffer, texcoord);

float Y_og;

[branch]if(Linear==false){
Y_og =rgb2Y(c0.rgb,Mode);
}else{
Y_og =LinRGB2Y(c0.rgb,Mode);
}

float4 c1=c0;
float3 c0_hsv=rgb2hsv(c0.rgb);

int hue=floor(c0_hsv.x*3600);
int grey=((c0.r==c0.g)&&(c0.g==c0.b))?1:0;

float new_hue=0;

[flatten]if((hue>=3525)||(((hue>=0) && (hue<75))&&(grey==0))){
new_hue=((Red==true)&&(Red_Rotate!=0))?hue_rotate(c0_hsv.x,Red_Rotate):c0_hsv.x;
}else if((hue>=75) && (hue<375)){
new_hue=((Orange__Brown==true)&&(Orange__Brown_Rotate!=0))?hue_rotate(c0_hsv.x,Orange__Brown_Rotate):c0_hsv.x;
}else if((hue>=375) && (hue<675)){
new_hue=((Yellow==true)&&(Yellow_Rotate!=0))?hue_rotate(c0_hsv.x,Yellow_Rotate):c0_hsv.x;
}else if((hue>=675) && (hue<975)){
new_hue=((Chartreuse_Lime==true)&&(Chartreuse_Lime_Rotate!=0))?hue_rotate(c0_hsv.x,Chartreuse_Lime_Rotate):c0_hsv.x;
}else if((hue>=975) && (hue<1275)){
new_hue=((Green==true)&&(Green_Rotate!=0))?hue_rotate(c0_hsv.x,Green_Rotate):c0_hsv.x;
}else if((hue>=1275) && (hue<1575)){
new_hue=((Spring_green==true)&&(Spring_green_Rotate!=0))?hue_rotate(c0_hsv.x,Spring_green_Rotate):c0_hsv.x;
}else if((hue>=1575) && (hue<1875)){
new_hue=((Cyan==true)&&(Cyan_Rotate!=0))?hue_rotate(c0_hsv.x,Cyan_Rotate):c0_hsv.x;
}else if((hue>=1875) && (hue<2175)){
new_hue=((Azure__Sky_blue==true)&&(Azure__Sky_blue_Rotate!=0))?hue_rotate(c0_hsv.x,Azure__Sky_blue_Rotate):c0_hsv.x;
}else if((hue>=2175) && (hue<2475)){
new_hue=((Blue==true)&&(Blue_Rotate!=0))?hue_rotate(c0_hsv.x,Blue_Rotate):c0_hsv.x;
}else if((hue>=2475) && (hue<3075)){
new_hue=((Violet__Purple==true)&&(Violet__Purple_Rotate!=0))?hue_rotate(c0_hsv.x,Violet__Purple_Rotate):c0_hsv.x;
}else if((hue>=3075) && (hue<3375)){
new_hue=((Magenta__Pink==true)&&(Magenta__Pink_Rotate!=0))?hue_rotate(c0_hsv.x,Magenta__Pink_Rotate):c0_hsv.x;
}else if((hue>=3375) && (hue<3525)){
new_hue=((Reddish_pink==true)&&(Reddish_pink_Rotate!=0))?hue_rotate(c0_hsv.x,Reddish_pink_Rotate):c0_hsv.x;
}

[branch]if(Linear==false){
c1.rgb=xyY2rgb(
		float3(rgb2xyY(
						hsv2rgb(float3(new_hue,c0_hsv.yz))
						,Mode
									).xy,
					Y_og)
			, Mode);

}else{
c1.rgb=xyY2LinRGB(
		float3(LinRGB2xyY(
						hsv2rgb(float3(new_hue,c0_hsv.yz))
						,Mode
									).xy,
					Y_og)
			, Mode);
}

return c1;

}

technique Selective_hue_rotate_xy
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = selHueRotPass;
	}
}
