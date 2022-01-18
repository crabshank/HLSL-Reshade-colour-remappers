#include "ReShadeUI.fxh"


uniform float Value < __UNIFORM_DRAG_FLOAT1
	ui_min = 0; ui_max = 1;  ui_tooltip = "Disabled if =0";
> = 0.63;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

#define PI acos(-1)

float4 Saturated_hues_Pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float4 c1=c0;

float3 c1_hsv=rgb2hsv(c0.rgb);

int grey=(((c0.r==c0.g)&&(c0.g==c0.b))||(c1_hsv.y==0))?1:0;

c1_hsv.y=1;
c1_hsv.z=Value;

c1.rgb=(grey==1)?Value:hsv2rgb(c1_hsv);

return c1;

}

technique Saturated_hues
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Saturated_hues_Pass;
	}
}