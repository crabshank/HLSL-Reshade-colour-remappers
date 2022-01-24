#include "ReShadeUI.fxh"

uniform int mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0Orignal NTSC D65\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform float2 Custom_xy < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_step=0.001; ui_max = 1.0;
	ui_tooltip = "N.B. output will be D65 (white point for most colour spaces)";
> =float2(0.312727,0.329023);

#include "ReShade.fxh"
#include "xyY_funcs.fxh"
#include "DrawText_mod.fxh"

float3 WPChangeRGB(float3 color, float3 from, float3 to, int mode, int lin)
{		
	[branch]if(lin==0){
		float3 XYZed=rgb2XYZ(color.rgb,mode);
		return XYZ2rgb(WPconv(XYZed,from,to),mode);
	}else{
		float3 XYZed=LinRGB2XYZ(color.rgb,mode);
		return XYZ2LinRGB(WPconv(XYZed,from,to),mode);
	}
}

float4 whitePoint(float4 color, float2 CustomxyIn, int lin){

float4 c0=color;

float2 D65xy=float2(0.312727,0.329023);

float3 D65XYZ=xy2XYZ(D65xy);
float3 CustomXYZ=xy2XYZ(CustomxyIn);

float3 from = D65XYZ; 
float3 to = CustomXYZ;

color.rgb= WPChangeRGB(color.rgb, from, to,mode,lin);

return color;
}

float4 WhitePointPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
float4 c0=tex2D(ReShade::BackBuffer, texcoord);

int linr=(Linear==true)?1:0;

float2 Customxy=Custom_xy;

float4 c1=whitePoint(c0,Customxy,linr);

return c1;
}

technique White_Point_No_Debug
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = WhitePointPass;
	}
}
