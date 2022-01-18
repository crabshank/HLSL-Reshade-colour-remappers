#include "ReShadeUI.fxh"

uniform float Out_value < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max =1;
> = 0.630;

uniform int Grey_colour < __UNIFORM_COMBO_INT1
    ui_items = "Black\0Mid_grey\0White\0";
> = 2;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float4 Discrete_hues_Pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float4 c1=c0;

float3 c0_hsv=rgb2hsv(c0.rgb);

int hue=floor(c0_hsv.x*3600);
float hueCol;
int grey=(((c0.r==c0.g)&&(c0.g==c0.b))||(c0_hsv.y==0))?1:0;

[flatten]if(grey==0){
	
float hueSat=1.0;

if((hue>=3525)||(((hue>=0) && (hue<75)))){
hueCol=0.0;
}else if((hue>=75) && (hue<375)){
hueCol=30.0;
}else if((hue>=375) && (hue<675)){
hueCol=60.0;
}else if((hue>=675) && (hue<975)){
hueCol=90.0;
}else if((hue>=975) && (hue<1275)){
hueCol=120.0;
}else if((hue>=1275) && (hue<1575)){
hueCol=150.0;
}else if((hue>=1575) && (hue<1875)){
hueCol=180.0;
}else if((hue>=1875) && (hue<2175)){
hueCol=210.0;
}else if((hue>=2175) && (hue<2475)){
hueCol=240.0;
}else if((hue>=2475) && (hue<3075)){
hueCol=270.0;
}else if((hue>=3075) && (hue<3375)){
hueCol=330.0;
hueSat=0.8;
}else if((hue>=3375) && (hue<3525)){
hueCol=345.0;
hueSat=0.95;
}

c1.rgb=hsv2rgb(float3(hueCol/360.0,hueSat,Out_value));

}else{
	
	float greyOut;
	
	[flatten]if(Grey_colour==2){
		greyOut=1;
	}else if(Grey_colour==0){
		greyOut=0;
	}else{
		greyOut=0.5;
	}
	
	c1.rgb=hsv2rgb(float3(0.0,0.0,greyOut));
	
}

return c1;

}

technique Discrete_hues
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Discrete_hues_Pass;
	}
}