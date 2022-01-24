#include "ReShadeUI.fxh"

uniform int mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0Orignal NTSC D65\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform float3 Custom_RGB < __UNIFORM_COLOR_FLOAT3
	ui_tooltip = "N.B. output will be D65 (white point for most colour spaces)";
> = float3(1, 1, 1);

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

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

float4 WhitePoint_RGB_No_DebugPass2D(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float4 c1=c0;
float4 c0Lin;
int linr=(Linear==true)?1:0;

[flatten]if(linr==1){
	c0Lin=c0;
}else{
	c0Lin.rgb=rgb2LinRGB(c0.rgb,mode);
}

float4 p0=float4(1,1,1,1);
float4 p0_rnd=float4(255,255,255,255);
float2 Customxy=float2(0.312727,0.329023);

float3 p0_wp=Custom_RGB;

float3 WPgf;
float3 WPgt;

[branch]if(linr==0){
	WPgf= rgb2XYZ(p0_wp.rgb,mode);
	WPgt= rgb2XYZ_grey(p0_wp.rgb,mode);
}else{
	WPgf= LinRGB2XYZ(p0_wp.rgb,mode);
	WPgt= LinRGB2XYZ_grey(p0_wp.rgb,mode);
}

Customxy.xy=XYZ2xyY(WPconv2Grey(WPgf,WPgt)).xy;

float4 c1_lin=whitePoint(c0Lin,Customxy,1); 

	[flatten]if(linr==0){
		c1.rgb=LinRGB2rgb(c1_lin.rgb,mode);
	}else{
		c1.rgb=c1_lin.rgb;
	}

return c1;

}

technique White_Point_RGB_No_Debug
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = WhitePoint_RGB_No_DebugPass2D;
	}
}
