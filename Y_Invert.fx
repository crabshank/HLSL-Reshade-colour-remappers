#include "ReShadeUI.fxh"

uniform int Mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0Orignal NTSC D65\0";
> = 3;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float4 Y_Invert_Pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float3 c0xyY;
float3 c1xyY;
float3 c0hsv;

c0hsv=rgb2hsv(c0.rgb);

[branch]if(Linear==true){
c0xyY=LinRGB2xyY(c0.rgb,Mode);

c0hsv.z=1-c0hsv.z;

c1xyY=LinRGB2xyY(hsv2rgb(c0hsv),Mode);

return float4 (xyY2LinRGB(float3(c0xyY.xy,c1xyY.z),Mode),c0.w);

}else{
	
c0xyY=rgb2xyY(c0.rgb,Mode);

c0hsv.z=1-c0hsv.z;

c1xyY=rgb2xyY(hsv2rgb(c0hsv),Mode);

return float4 (xyY2rgb(float3(c0xyY.xy,c1xyY.z),Mode),c0.w);

}

}

technique Y_Invert
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Y_Invert_Pass;
	}
}