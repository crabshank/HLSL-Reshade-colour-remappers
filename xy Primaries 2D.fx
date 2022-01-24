#include "ReShadeUI.fxh"

uniform int From_space < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0Orignal NTSC D65\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform float2 To_Red < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_step=0.000001; ui_max = 1.0;
> =float2(0.64,0.33);

uniform float2 To_Green < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_step=0.000001; ui_max = 1.0;
> =float2(0.3,0.6);

uniform float2 To_Blue < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_step=0.000001; ui_max = 1.0;
> =float2(0.15,0.06);

uniform bool Two_dimensional_input <> = false;

uniform int Two_dimensional_input_primary <__UNIFORM_COMBO_INT1
    ui_items = "Red\0Green\0Blue\0";
	> = 0;

uniform int Two_dimensional_input_type <__UNIFORM_COMBO_INT1
    ui_items = "Crosshairs on\0Crosshairs off\0Direct point-based\0";
	> = 0;

uniform float Two_dimensional_input_Range < __UNIFORM_SLIDER_FLOAT1
	ui_min = 2; ui_max = 0.0;
> = 1.89;

uniform bool Debug <> = false;

uniform int Debug_type <__UNIFORM_COMBO_INT1
    ui_items = "Distance from pure primary\0Colour bars\0";
	> = 0;

uniform float Debug_amplification < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0000001; ui_max =2;
	ui_tooltip = "A lower value exaggerates small differences more";
> = 0.5;

uniform int Decimals < __UNIFORM_SLIDER_INT1
	ui_min = 2; ui_max =4;
> = 3;

uniform bool Split <> = false;

uniform bool Flip_split <> = false;

uniform float Split_position < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max =1;
	ui_tooltip = "0 is on the far left, 1 on the far right.";
> = 0.5;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"
#include "DrawText_mod.fxh"

#define third 1.0/3.0

uniform bool buttondown < source = "mousebutton"; keycode = 0; mode = ""; >;

uniform float2 mousepoint < source = "mousepoint"; >;

float3x3 invThreeByThreeMatrix(float3x3 mtx){

float el_A=mtx[1][1]*mtx[2][2]-mtx[1][2]*mtx[2][1];
float el_B=-(mtx[1][0]*mtx[2][2]-mtx[1][2]*mtx[2][0]);
float el_C=mtx[1][0]*mtx[2][1]-mtx[1][1]*mtx[2][0];
float el_D=-(mtx[0][1]*mtx[2][2]-mtx[0][2]*mtx[2][1]);
float el_E=mtx[0][0]*mtx[2][2]-mtx[0][2]*mtx[2][0];
float el_F=-(mtx[0][0]*mtx[2][1]-mtx[0][1]*mtx[2][0]);
float el_G=mtx[0][1]*mtx[1][2]-mtx[0][2]*mtx[1][1];
float el_H=-(mtx[0][0]*mtx[1][2]-mtx[0][2]*mtx[1][0]);
float el_I=mtx[0][0]*mtx[1][1]-mtx[0][1]*mtx[1][0];

float det=mtx[0][0]*el_A+mtx[0][1]*el_B+mtx[0][2]*el_C;

float invDet=1/det;

float3x3 outp=invDet*float3x3(el_A,el_D,el_G,
el_B,el_E,el_H,
el_C,el_F,el_I);

    return outp;
}

float3 Primaryconv(float2 red, float2 green, float2 blue, float3 XYZ, int lin, int mode){

float3 XYZ_r=float3(red.xy,1-red.x-red.y);
float3 XYZ_g=float3(green.xy,1-green.x-green.y);
float3 XYZ_b=float3(blue.xy,1-blue.x-blue.y);

float3x3 XYZ_rgb=float3x3(XYZ_r.x,XYZ_g.x,XYZ_b.x,
XYZ_r.y,XYZ_g.y,XYZ_b.y,
XYZ_r.z,XYZ_g.z,XYZ_b.z);

float3x3 inv_XYZ_rgb=invThreeByThreeMatrix(XYZ_rgb);

float3 WP=float3(0.95047,1,1.08883); //D65

[branch]if(mode==5){
WP=float3(0.8945869,1,0.954416);
}else if((mode==8)||(mode==9)){
WP=float3(0.9528778,1,1.4129923);
}else if(mode==10){
WP=float3(0.9526461,1,1.0088252);
}

float3 s_XYZ=mul(inv_XYZ_rgb,WP);

float3x3 s_mat=float3x3(s_XYZ.x,0,0,
0,s_XYZ.y,0,
0,0,s_XYZ.z);

float3x3 inv_s_mat=invThreeByThreeMatrix(mul(XYZ_rgb,s_mat));

float3 rgb_i=mul(inv_s_mat,XYZ);

float3 RGB=rgb_i;

[branch]if(lin==0){
if ((mode==0)||(mode==6)){ //sRGB transfer
      RGB=(rgb_i> 0.00313066844250063)?1.055 * pow(rgb_i,rcpTwoFour) - 0.055:12.92 *rgb_i;
}else if ((mode==5)||(mode==10)){ //DCI-P3
      RGB=pow(rgb_i,invTwoSix);
}else if (mode==7 || mode==11){ //Original NTSC - Source: 47 CFR, Section 73.682 - TV transmission standards
      RGB=pow(rgb_i,invTwoTwo);
}else{ //Rec transfer
      RGB=(rgb_i< recBeta)?4.5*rgb_i:recAlpha*pow(rgb_i,0.45)-(recAlpha-1);
}
}

	return RGB;

}
//Source: http://www.ryanjuckett.com/programming/rgb-color-space-conversion/

float4 PrimariesChangePass2D(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0 = tex2D(ReShade::BackBuffer, texcoord);

float2 Customxy;

float2 to_Red=To_Red;
float2 to_Green=To_Green;
float2 to_Blue=To_Blue;
int linr=(Linear==true)?1:0;

[branch]if(Two_dimensional_input_primary==0){
Customxy=to_Red;
}else if(Two_dimensional_input_primary==1){
Customxy=to_Green;
}else if(Two_dimensional_input_primary==2){
Customxy=to_Blue;
}

float x_Range=(BUFFER_WIDTH>=BUFFER_HEIGHT)?Two_dimensional_input_Range*(BUFFER_RCP_HEIGHT/BUFFER_RCP_WIDTH):Two_dimensional_input_Range;

float y_Range=(BUFFER_WIDTH>=BUFFER_HEIGHT)?Two_dimensional_input_Range:Two_dimensional_input_Range*(BUFFER_RCP_WIDTH/BUFFER_RCP_HEIGHT);

Customxy.x= ((Two_dimensional_input==1 && Debug_type==1 && buttondown==1)||(buttondown==0 && Two_dimensional_input==1))?x_Range*(mousepoint.x*BUFFER_RCP_WIDTH-0.5)+Customxy.x:Customxy.x;

float xCoord_Pos=((Two_dimensional_input==1 && Debug_type==1 && buttondown==1)||(buttondown==1 && Two_dimensional_input==1))?0.5:mousepoint.x*BUFFER_RCP_WIDTH;

Customxy.y=((Two_dimensional_input==1 && Debug_type==1 && buttondown==1)||(buttondown==0 && Two_dimensional_input==1))?y_Range*(mousepoint.y*BUFFER_RCP_HEIGHT-0.5)+Customxy.y:Customxy.y;

float yCoord_Pos=(buttondown==1 && Two_dimensional_input==1)?0.5:mousepoint.y*BUFFER_RCP_HEIGHT;

float4 c1=c0;
float2 c_xy;
[branch]if(linr==0){
	c_xy=rgb2xyY(tex2D(ReShade::BackBuffer, mousepoint*float2(BUFFER_RCP_WIDTH,BUFFER_RCP_HEIGHT)).rgb,From_space).xy;
}else{
	c_xy=LinRGB2xyY(tex2D(ReShade::BackBuffer, mousepoint*float2(BUFFER_RCP_WIDTH,BUFFER_RCP_HEIGHT)).rgb,From_space).xy;
}
Customxy=(Two_dimensional_input==1 && Two_dimensional_input_type==2)?c_xy:Customxy;

[branch]if(Two_dimensional_input==1 && Two_dimensional_input_primary==0){
to_Red=Customxy;
}else if(Two_dimensional_input==1 && Two_dimensional_input_primary==1){
to_Green=Customxy;
}else if(Two_dimensional_input==1 && Two_dimensional_input_primary==2){
to_Blue=Customxy;
}

[branch]if(linr==0){
	c1.rgb=Primaryconv(to_Red,to_Green,to_Blue,rgb2XYZ(c0.rgb,From_space),linr,From_space);
}else{
	c1.rgb=Primaryconv(to_Red,to_Green,to_Blue,LinRGB2XYZ(c0.rgb,From_space),linr,From_space);
}

float3 dbgCol=float3(0,0,0);

[branch]if(Debug==1){

dbgCol=(texcoord.x<=third)?float3(1,0,0):dbgCol;
dbgCol=(texcoord.x>third && texcoord.x<=2*third)?float3(0,1,0):dbgCol;
dbgCol=(texcoord.x>2*third)?float3(0,0,1):dbgCol;

float2 OGxy;
float2 Currxy;

[branch]if(linr==0){
	OGxy=rgb2xyY(c0.rgb,From_space).xy;
	Currxy=rgb2xyY(c1.rgb,From_space).xy;
}else{
	OGxy=LinRGB2xyY(c0.rgb,From_space).xy;
	Currxy=LinRGB2xyY(c1.rgb,From_space).xy;
}

[branch]if(Two_dimensional_input_primary==0){

if(Debug_type==0){
c1.rgb=pow(min(1,sqrt(pow(0.64-Currxy.x,2)+pow(0.33-Currxy.y,2))),Debug_amplification);
c0.rgb=(Split==1)?pow(min(1,sqrt(pow(0.64-OGxy.x,2)+pow(0.33-OGxy.y,2))),Debug_amplification):c0.rgb;
}else{
	
[branch]if(linr==0){
		c1.rgb=(buttondown==1)?c1.rgb:Primaryconv(to_Red,to_Green,to_Blue,rgb2XYZ(dbgCol,From_space),linr,From_space);
}else{
	c1.rgb=(buttondown==1)?c1.rgb:Primaryconv(to_Red,to_Green,to_Blue,LinRGB2XYZ(dbgCol,From_space),linr,From_space);
}


c0.rgb=c1.rgb;
}

}else if(Two_dimensional_input_primary==1){

if(Debug_type==0){
c1.rgb=pow(min(1,sqrt(pow(0.3-Currxy.x,2)+pow(0.6-Currxy.y,2))),Debug_amplification);
c0.rgb=(Split==1)?pow(min(1,sqrt(pow(0.3-OGxy.x,2)+pow(0.6-OGxy.y,2))),Debug_amplification):c0.rgb;
}else{
[branch]if(linr==0){
		c1.rgb=(buttondown==1)?c1.rgb:Primaryconv(to_Red,to_Green,to_Blue,rgb2XYZ(dbgCol,From_space),linr,From_space);
}else{
	c1.rgb=(buttondown==1)?c1.rgb:Primaryconv(to_Red,to_Green,to_Blue,LinRGB2XYZ(dbgCol,From_space),linr,From_space);
}
c0.rgb=c1.rgb;
}

}else if(Two_dimensional_input_primary==2){

if(Debug_type==0){
c1.rgb=pow(min(1,sqrt(pow(0.15-Currxy.x,2)+pow(0.06-Currxy.y,2))),Debug_amplification);
c0.rgb=(Split==1)?pow(min(1,sqrt(pow(0.15-OGxy.x,2)+pow(0.06-OGxy.y,2))),Debug_amplification):c0.rgb;
}else{
[branch]if(linr==0){
		c1.rgb=(buttondown==1)?c1.rgb:Primaryconv(to_Red,to_Green,to_Blue,rgb2XYZ(dbgCol,From_space),linr,From_space);
}else{
	c1.rgb=(buttondown==1)?c1.rgb:Primaryconv(to_Red,to_Green,to_Blue,LinRGB2XYZ(dbgCol,From_space),linr,From_space);
}
c0.rgb=c1.rgb;
}

}
}

float4 c2=(texcoord.x>=Split_position*Split)?c1:c0;
float4 c3=(texcoord.x<=Split_position*Split)?c1:c0;

float4 c4=(Flip_split==1 && Split==1)?c3:c2;

float divLine = abs(texcoord.x - Split_position) < BUFFER_RCP_WIDTH;
c4 =(Split==0 || (Debug==1 && Debug_type==1))?c4: c4*(1.0 - divLine); //invert divline

c4.rgb =(Two_dimensional_input==1 && Two_dimensional_input_type==0 && (abs(texcoord.x-xCoord_Pos)<BUFFER_RCP_WIDTH || abs(texcoord.y-yCoord_Pos)<BUFFER_RCP_HEIGHT))?float3(0.369,0.745,0):c4.rgb;

c4.rgb =((Two_dimensional_input==1 && Two_dimensional_input_type==1 && (abs(texcoord.x-xCoord_Pos)<3*BUFFER_RCP_WIDTH && abs(texcoord.y-yCoord_Pos)<3*BUFFER_RCP_HEIGHT))||(Two_dimensional_input==1 && buttondown==1 && Debug==1 && Debug_type==1)&& (abs(texcoord.x-mousepoint.x*BUFFER_RCP_WIDTH)<3*BUFFER_RCP_WIDTH && abs(texcoord.y-mousepoint.y*BUFFER_RCP_HEIGHT)<3*BUFFER_RCP_HEIGHT) && Two_dimensional_input_type!=2)?float3(0.498,1,0):c4.rgb;

float4 res =float4(c4.rgb,0);

float textSize=25;

[flatten]if(Two_dimensional_input==1){
    DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(-14, 0), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  Decimals, Customxy.x, res,0);
						
						    DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(-5, 0), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  Decimals,  Customxy.y, res,0);
}

c4.rgb=res.rgb;

return c4;
}

technique xy_Primaries_2D
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PrimariesChangePass2D;
	}
}