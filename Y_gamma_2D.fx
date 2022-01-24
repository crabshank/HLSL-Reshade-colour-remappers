#include "ReShadeUI.fxh";

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

uniform bool Two_dimensional_input <> = false;


uniform int Two_dimensional_input_type <__UNIFORM_COMBO_INT1
    ui_items = "Crosshairs on\0Crosshairs off\0";
	> = 0;

uniform float Two_dimensional_input_Range < __UNIFORM_SLIDER_FLOAT1
	ui_min = 20; ui_max = 0.0;
> = 2;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"
#include "DrawText_mod.fxh"

uniform bool buttondown < source = "mousebutton"; keycode = 0; mode = ""; >;

uniform float2 mousepoint < source = "mousepoint"; >;

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

float4 Y_gamma_2D_pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float3 c0_hsv=rgb2hsv(c0.rgb);

float xCoord_Pos;
float yCoord_Pos;
float Y_Gamma_lo=Y_Gamma_Lo;
float Y_Gamma_hi=Y_Gamma_Hi;

[branch]if(Two_dimensional_input==true){
	
float x_Range=(BUFFER_WIDTH>=BUFFER_HEIGHT)?Two_dimensional_input_Range*(BUFFER_RCP_HEIGHT/BUFFER_RCP_WIDTH):Two_dimensional_input_Range;

float y_Range=(BUFFER_WIDTH>=BUFFER_HEIGHT)?Two_dimensional_input_Range:Two_dimensional_input_Range*(BUFFER_RCP_WIDTH/BUFFER_RCP_HEIGHT);

Y_Gamma_lo= (buttondown==0)?x_Range*(mousepoint.x*BUFFER_RCP_WIDTH-0.5)+Y_Gamma_lo:Y_Gamma_lo;

xCoord_Pos=(buttondown==1)?0.5:mousepoint.x*BUFFER_RCP_WIDTH;

Y_Gamma_hi= (buttondown==0)?y_Range*(mousepoint.y*BUFFER_RCP_HEIGHT-0.5)+Y_Gamma_hi:Y_Gamma_hi;

yCoord_Pos=(buttondown==1)?0.5:mousepoint.y*BUFFER_RCP_HEIGHT;

}


float4 c1=change(c0,Y_Gamma_lo,Y_Gamma_hi);

c1.rgb =(Two_dimensional_input==1 && Two_dimensional_input_type==0 && (abs(texcoord.x-xCoord_Pos)<BUFFER_RCP_WIDTH || abs(texcoord.y-yCoord_Pos)<BUFFER_RCP_HEIGHT))?float3(0.369,0.745,0):c1.rgb;

c1.rgb =(Two_dimensional_input==1 && Two_dimensional_input_type==1 && (abs(texcoord.x-xCoord_Pos)<3*BUFFER_RCP_WIDTH && abs(texcoord.y-yCoord_Pos)<3*BUFFER_RCP_HEIGHT))?float3(0.498,1,0):c1.rgb;

float4 res =float4(c1.rgb,0);
float textSize=33;
[flatten]if(Two_dimensional_input==1){
    DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(-9, 0), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  3, Y_Gamma_lo, res,1); 
						
						
						DrawText_Digit(DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(-9, 1), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  3, Y_Gamma_hi, res,1);
}
c1.rgb=res.rgb;
return c1;

}

technique Y_gamma_2D
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Y_gamma_2D_pass;
	}
}
