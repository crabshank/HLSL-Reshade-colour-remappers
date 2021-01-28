#include "ReShadeUI.fxh"

uniform float Amplification < __UNIFORM_DRAG_FLOAT1
ui_min = 0.0; ui_max = 10.0;
> = 1.25;

uniform bool Split <> = false;

uniform bool Flip_split <> = false;

uniform float Split_position < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max =1;
	ui_tooltip = "0 is on the far left, 1 on the far right.";
> = 0.5;


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

float4 c2=(texcoord.x>=Split_position*Split)?c1:c0;
float4 c3=(texcoord.x<=Split_position*Split)?c1:c0;

float4 c4=(Flip_split==1 && Split==1)?c3:c2;

float divLine = abs(texcoord.x - Split_position) < BUFFER_RCP_WIDTH;
c4 =(Split==0)?c4: c4*(1.0 - divLine); //invert divline

return c4;

}

technique Max_RGB
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Max_RGB_Pass;
	}
}