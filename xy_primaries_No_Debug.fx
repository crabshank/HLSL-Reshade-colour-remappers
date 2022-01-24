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
}else if (mode==7 || mode ==11){ //Original NTSC - Source: 47 CFR, Section 73.682 - TV transmission standards
      RGB=pow(rgb_i,invTwoTwo);
}else{ //Rec transfer
      RGB=(rgb_i< recBeta)?4.5*rgb_i:recAlpha*pow(rgb_i,0.45)-(recAlpha-1);
}
}

	return RGB;

}
//Source: http://www.ryanjuckett.com/programming/rgb-color-space-conversion/

float4 PrimariesChangePass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0 = tex2D(ReShade::BackBuffer, texcoord);

float2 Customxy;

float2 to_Red=To_Red;
float2 to_Green=To_Green;
float2 to_Blue=To_Blue;
int linr=(Linear==true)?1:0;

[branch]if(linr==0){
	c0.rgb=Primaryconv(to_Red,to_Green,to_Blue,rgb2XYZ(c0.rgb,From_space),linr,From_space);
}else{
	c0.rgb=Primaryconv(to_Red,to_Green,to_Blue,LinRGB2XYZ(c0.rgb,From_space),linr,From_space);
}

return c0;
}

technique xy_Primaries
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PrimariesChangePass;
	}
}