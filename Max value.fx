#include "ReShade.fxh"

#define PI acos(-1)

float4 Max_value_Pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float4 c1=c0;

float mx=max(c0.r,max(c0.g,c0.b));

c1.rgb=saturate((mx==0)?1:c1.rgb/mx);

return c1;

}

technique Max_value
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Max_value_Pass;
	}
}