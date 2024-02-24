#include "ReShadeUI.fxh"

#define rcpTwoFour 1.0/2.4
#define rcpOFiveFive 1.0/1.055
#define rcpTwelveNineTwo 1.0/12.92
#define recAlpha 1.09929682680944
#define rcpRecAlpha 1.0/1.09929682680944
#define recBeta 0.018053968510807
#define recBetaLin 0.004011993002402
#define rcpFourFive 1.0/4.5
#define rcpTxFourFive 10.0/4.5
#define invTwoTwo 5.0/11.0
#define invTwoSix 5.0/13.0
#define third 1.0/3.0

uniform int Gamma_type < __UNIFORM_COMBO_INT1
    ui_items = "None\0sRGB -> linear RGB\0linear RGB -> sRGB\0Rec.(2020/601/709) RGB -> linear RGB\0linear RGB -> Rec.(2020/601/709) RGB\0gamma=2.2 -> linear RGB\0linear RGB -> gamma=2.2\0gamma=2.6 -> linear RGB\0linear RGB -> gamma=2.6\0gamma=2.4 -> linear RGB\0linear RGB -> gamma=2.4\0";
> = 0;

uniform int Gamma_type_2 < __UNIFORM_COMBO_INT1
    ui_items = "None\0sRGB -> linear RGB\0linear RGB -> sRGB\0Rec.(2020/601/709) RGB -> linear RGB\0linear RGB -> Rec.(2020/601/709) RGB\0gamma=2.2 -> linear RGB\0linear RGB -> gamma=2.2\0gamma=2.6 -> linear RGB\0linear RGB -> gamma=2.6\0gamma=2.4 -> linear RGB\0linear RGB -> gamma=2.4\0";
	ui_tooltip = "Transfer function for the second instance of the shader, if enabled.";
> = 0;

uniform float greyDitherAmnt < __UNIFORM_DRAG_FLOAT1
	ui_min = -255.0; ui_max = 255.0;
	ui_tooltip = "Change average value by specified amount.";
> = 0;

uniform float greyDitherSdv < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 255.0;
	ui_tooltip = "Change standard deviation value by specified amount.";
> = 0;

uniform float greyDitherScurve < __UNIFORM_DRAG_FLOAT1
	ui_min = -1.0; ui_max = 5.0;
> = 1;

uniform int Crushing_type < __UNIFORM_COMBO_INT1
    ui_items = "Crush to RGB average\0Crush to 0.5\0Crush to max RGB\0";
    ui_tooltip = "Crushing to 0.5 has a stronger de-dither effect but loses more information.";
> = 0;

uniform float Crushing_amnt < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 1.0;  ui_tooltip = "Disabled if =0";
> = 0;

uniform bool Dark_dither <> = false;

uniform float Dark_dither_pwr < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
> = 0;

uniform bool Crushing_debug <> = false;

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


float3 transferrer(float3 c0, int mode){

float3 c1=c0;

[branch]if (mode==2){ //sRGB transfer
    c1.rgb=(c0.rgb> 0.00313066844250063)?1.055 * pow(c0.rgb,rcpTwoFour) - 0.055:12.92 *c0.rgb;
}else if(mode==8){
    c1.rgb=pow(c0.rgb,invTwoSix);
}else if(mode==9){
    c1.rgb=pow(c0.rgb,2.4);
}else if(mode==10){
    c1.rgb=pow(c0.rgb,rcpTwoFour);
}else if (mode==6){
    c1.rgb=pow(c0.rgb,invTwoTwo);
}else if(mode==4){
    c1.rgb=(c0.rgb< recBeta)?4.5*c0.rgb:recAlpha*pow(c0.rgb,0.45)-(recAlpha-1);
}else if(mode==1){
    c1.rgb=(c0.rgb > 0.0404482362771082 )?pow(abs((c0.rgb+0.055)*rcpOFiveFive),2.4):c0.rgb*rcpTwelveNineTwo;
}else if(mode==7){
    c1.rgb=pow(c0.rgb,2.6);
}else if(mode==5){
    c1.rgb=pow(c0.rgb,2.2);
}else if(mode==3	){
    c1.rgb=(c0.rgb < recBetaLin )?rcpFourFive*c0.rgb:pow(-1*(rcpRecAlpha*(1-recAlpha-c0.rgb)),rcpTxFourFive);
}

return c1;

}

float random( float2 p )
{
// We need irrationals for pseudo randomness.
// Most (all?) known transcendental numbers will (generally) work.
const float2 r = float2(
23.1406926327792690,  // e^pi (Gelfond's constant)
 2.6651441426902251); // 2^sqrt(2) (Gelfond-Schneider constant)

float t=frac(acos(p.x/p.y)+sin(p.x)*r.y+cos(p.y)*r.x+p.x*p.y*r.y);

t= frac((800*cos(t/20)+1400)*t);  
t= frac(pow( frac((0.01*t+sin(500*t*t))+tan(t*500)*500),2));

float rMap =3.98;
float tOld=t;
int k=0;

for (k=0;k<100;k++){
tOld=rMap*tOld*(1-tOld);
}
 
 float w = frac(10000*tOld+0.597*tOld);

#define dither_points 7
float2 d[dither_points] = {
float2(0,0),
float2(1,0),
float2(64.90915,63.75),
float2(131.4898,127.5),
float2(194.1036,191.25),
float2(254,255),
float2(255,255)
};


float2 d_x_b=float2(0,1);float2 d_y_b=float2(0,1);
float dither=w;
int i=0; int exact=0; 
for(i=0;i<dither_points;i++){
[branch]if(d[i].x/255==dither) {dither=d[i].y/255;exact=1;i=dither_points-1;}else{if(d[i].x/255<dither&&d[i].x/255>=d_x_b.x){d_x_b.x=d[i].x/255;d_y_b.x=d[i].y/255;} if(d[i].x/255<=d_x_b.y&&dither<d[i].x/255){d_x_b.y=d[i].x/255;d_y_b.y=d[i].y/255;}}} if(exact==0){dither=d_y_b.x+(dither-d_x_b.x)*((d_y_b.y-d_y_b.x)/(d_x_b.y-d_x_b.x));};i=0;exact=0;

return dither;

}


float grey_dither(float color,float2 tex,float rnd,float sdv, float gamma){
tex.x=min(tex.x,abs(0.5-tex.x*0.5));
tex.y=max(tex.y,abs(0.5-tex.y*0.5));
float2 cxy=float2((0.5*(tex.x+color)+max(tex.x,color))*0.5,(0.5*(tex.y+color)+max(tex.y,color))*0.5);
float rand=random(cxy);
float randm=rnd*-1*((rand*-4)+1); // averages to color + rnd

color =(rnd!=0)?color+(randm/255):color;

float sAB=sdv*sqrt(12)*0.5;	
randm=sAB*(2*rand-1)*-1;

color =(sdv!=0)?color+(randm/255):color;

float colorSc=color*2;
randm=(colorSc<0.5)?(pow(abs(0.5*colorSc),gamma)-color)*-1*((rand*-4)+1):((1-(0.5*pow(abs(2-colorSc),gamma)))-color)*-1*((rand*-4)+1);
color =(gamma!=1)?color+randm:color;

return color;
}


float4 crusher(float4 color){
float4 c0=color;
float3 colorHSV=rgb2hsv(c0.rgb);

float rgbAvg=dot(c0.rgb,third);

float rgbMx=max(color.r,max(color.g,color.b));

float distGrey=sqrt(pow(rgbAvg-c0.r,2)+pow(rgbAvg-c0.g,2)+pow(rgbAvg-c0.b,2));
float normDistGrey=distGrey*pow(0.5*sqrt(3),-1);
float crsh=1-Crushing_amnt;
float lerper=pow(normDistGrey,Crushing_amnt);

float3 crshAvg=lerp(c0.rgb,rgbAvg,lerper);

float3 crshMx=lerp(c0.rgb,rgbMx,lerper);

float mxOld=max(c0.r,max(c0.g,c0.b));
//float mnOld=min(c0.r,min(c0.g,c0.b));
float mxNew=max(crshAvg.r,max(crshAvg.g,crshAvg.b));
float MAX_New=max(crshMx.r,max(crshMx.g,crshMx.b));
//float mnNew=min(crshAvg.r,min(crshAvg.g,crshAvg.b));

float3 avgRevert=(mxNew==0)?0:c0.rgb*(crshAvg.rgb/mxNew);

float3 mxRevert=(MAX_New==0)?0:c0.rgb*(crshMx.rgb/mxNew);

float3 crshHalf=(0.5-0.5*crsh) + ((0.5+0.5*crsh) - (0.5-0.5*crsh)) * c0.rgb;

colorHSV.yz=rgb2hsv(crshHalf.rgb).yz;

float fromMin=0.5-0.5*crsh;
float fromMax=0.5+0.5*crsh;

float3 halfRevert=	 ((c0.rgb - fromMin) / (fromMax - fromMin));

float3 c1=(Crushing_debug==1)?crshAvg:avgRevert;
float3 c2=(Crushing_debug==1)?hsv2rgb(colorHSV):halfRevert;
float3 c3=(Crushing_debug==1)?crshMx:mxRevert;

float3 c4=(Crushing_type==0)?c1:c2;
float3 c5=(Crushing_type==2)?c3:c4;

return float4(c5.xyz,color.w);
}

float4 PS_GreyDither(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{	

	float4 c0 = tex2D(ReShade::BackBuffer, texcoord);
	float4 c0OG = c0;
	c0.rgb=transferrer(c0.rgb, Gamma_type);
	float c0Max=max(c0.r,max(c0.g,c0.b));
	float4 c1 = c0;

c1.rgb =saturate(grey_dither(c0Max,texcoord,greyDitherAmnt,greyDitherSdv,greyDitherScurve)*(c1.rgb/c0Max));
	float c1Max=max(c1.r,max(c1.g,c1.b));

c1.rgb=(Dark_dither==1)?lerp(c1.rgb,c0.rgb,pow(c1Max,1-Dark_dither_pwr)):c1.rgb;

c1.rgb=(Crushing_amnt==0)?c1.rgb:crusher(c1).rgb;

c1.rgb=transferrer(c1.rgb, Gamma_type_2);

return c1;

}

technique GreyDither {
	pass GreyDither {
		VertexShader=PostProcessVS;
		PixelShader=PS_GreyDither;
	}
}