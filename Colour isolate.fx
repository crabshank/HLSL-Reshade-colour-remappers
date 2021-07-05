#include "ReShadeUI.fxh"

uniform int Colour < __UNIFORM_COMBO_INT1
    ui_items = "Greyscale\0Red\0Orange/Brown\0Yellow\0Chartreuse/Lime\0Green\0Spring green\0Cyan\0Azure/Sky blue\0Blue\0Violet/Purple\0Magenta/Pink\0Reddish Pink\0Custom\0";
> = 1;

uniform float Custom_from < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max =360;
> = 0;

uniform float Custom_to < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max =360;
> = 360;

#include "ReShade.fxh"

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


float4 Colour_Isolate_Pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float4 c1=c0;

float3 c0_hsv=rgb2hsv(c0.rgb);

int Col=Colour;

int hue=floor(c0_hsv.x*3600);

int grey=(((c0.r==c0.g)&&(c0.g==c0.b))||(c0_hsv.y==0))?1:0;

float Cust_from=Custom_from*pow(360,-1);
float Cust_to=Custom_to*pow(360,-1);

[flatten]if(Col==0){
c1.rgb=(grey==1)?c0.rgb:0;
}else if(Col==1){
c1.rgb=((hue>=3525)||(((hue>=0) && (hue<75))&&(grey==0)))?c0.rgb:c0_hsv.z;
}else if(Col==2){
c1.rgb=((hue>=75) && (hue<375))?c0.rgb:c0_hsv.z;
}else if(Col==3){
c1.rgb=((hue>=375) && (hue<675))?c0.rgb:c0_hsv.z;
}else if(Col==4){
c1.rgb=((hue>=675) && (hue<975))?c0.rgb:c0_hsv.z;
}else if(Col==5){
c1.rgb=((hue>=975) && (hue<1275))?c0.rgb:c0_hsv.z;
}else if(Col==6){
c1.rgb=((hue>=1275) && (hue<1575))?c0.rgb:c0_hsv.z;
}else if(Col==7){
c1.rgb=((hue>=1575) && (hue<1875))?c0.rgb:c0_hsv.z;
}else if(Col==8){
c1.rgb=((hue>=1875) && (hue<2175))?c0.rgb:c0_hsv.z;
}else if(Col==9){
c1.rgb=((hue>=2175) && (hue<2475))?c0.rgb:c0_hsv.z;
}else if(Col==10){
c1.rgb=((hue>=2475) && (hue<3075))?c0.rgb:c0_hsv.z;
}else if(Col==11){
c1.rgb=((hue>=3075) && (hue<3375))?c0.rgb:c0_hsv.z;
}else if(Col==12){
c1.rgb=((hue>=3375) && (hue<3525))?c0.rgb:c0_hsv.z;
}else if(Col==13){
	[flatten]if(Cust_from>Cust_to){
		[flatten]if(((c0_hsv.x>=Cust_from)&&(c0_hsv.x<=1))||((c0_hsv.x>=0)&&(c0_hsv.x<=Cust_to))){
		c1.rgb=c0.rgb;
		}else{
		c1.rgb=c0_hsv.z;
		}
	}else{
		[flatten]if((c0_hsv.x>=Cust_from)&&(c0_hsv.x<=Cust_to)){
		c1.rgb=c0.rgb;
		}else{
		c1.rgb=c0_hsv.z;
		}
	}
}

return c1;

}

technique Colour_Isolate
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Colour_Isolate_Pass;
	}
}