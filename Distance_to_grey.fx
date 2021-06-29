#include "ReShadeUI.fxh"

uniform bool RGB_debug <> = false;

uniform float Amplification < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 10.0;
> = 0.3;

#include "ReShade.fxh"

float4 distGreyPass(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{

float4 c0 = tex2D(ReShade::BackBuffer, texcoord);

float4 c1=c0;
float rgbTot=c0.r+c0.g+c0.b;
float rgbAvg=pow(3,-1)*rgbTot;
float distGrey=sqrt(pow(abs(rgbAvg-c0.r),2)+pow(abs(rgbAvg-c0.g),2)+pow(abs(rgbAvg-c0.b),2));
c0.rgb=(RGB_debug==1)?pow(abs(rgbAvg-c0.rgb),Amplification):pow(abs((pow(abs(distGrey+1),2)-1)*pow(abs(pow(1+0.5*sqrt(3),2)-1),-1)),Amplification);
return c0;

}

technique Distance_to_grey
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = distGreyPass;
	}
}
