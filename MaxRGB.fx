#include "ReShadeUI.fxh"

uniform float Amplification < __UNIFORM_DRAG_FLOAT1
ui_min = 0.0; ui_max = 10.0;
> = 1.25;

#include "ReShade.fxh"


float4 Max_RGB_Pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{


float4 c0=tex2D(ReShade::BackBuffer, texcoord);

float4 c1 = c0;
	
float mx=max(max(c0.r,c0.g),c0.b);

float sat=(mx==0)?0:(mx-min(min(c0.r,c0.g),c0.b))/mx;

float dbOut=pow(sat,Amplification);

c1.r=(c0.r==mx)?dbOut:0;

c1.g=(c0.g==mx)?dbOut:0;

c1.b=(c0.b==mx)?dbOut:0;

return c1;

}

technique Max_RGB
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Max_RGB_Pass;
	}
}