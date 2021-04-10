#include "ReShadeUI.fxh";

uniform int Gamma < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec\0";
> = 0;

#include "ReShade.fxh"

#define rcptwoFiveFive 1.0/255.0
#define rcpTwoFour 1.0/2.4
#define rcpOFiveFive 1.0/1.055
#define rcpTwelveNineTwo 1.0/12.92
#define recAlpha 1.09929682680944
#define rcpRecAlpha 1.0/1.09929682680944
#define recBeta 0.018053968510807
#define recBetaLin 0.004011993002402
#define rcpFourFive 1.0/4.5
#define rcpTxFourFive 10.0/4.5

float rgb_2_Y_gc(float3 rgb){

    float3 rgbNew=rgb; 
	
		[flatten]if(Gamma==1){
		rgbNew=(rgb < recBetaLin )?rcpFourFive*rgb:pow(abs(-1*(rcpRecAlpha*(1-recAlpha-rgb))),rcpTxFourFive);
	}else{
		rgbNew=(rgb> 0.0404482362771082 )?pow(abs((rgb+0.055)*rcpOFiveFive),2.4):rgb*rcpTwelveNineTwo;
	}

		float Y= dot(float3(0.2126729,0.7151522,0.072175), rgbNew);
		float3 RGB_out;
		
	[flatten]if(Gamma==1){
		RGB_out=(rgbNew<recBeta)?4.5*rgbNew:recAlpha*pow(abs(rgbNew),0.45)-(recAlpha-1);
	}else{
		RGB_out=(rgbNew> 0.00313066844250063)?1.055 * pow(abs(rgbNew),rcpTwoFour) - 0.055:12.92 *rgbNew;
	}
	
	return RGB_out.r;
}


float4 Y_Greyscale_Pass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);

float4 c1 =c0;

c1.rgb= rgb_2_Y_gc(c0.rgb);

return c1;
}

technique Y_Greyscale
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Y_Greyscale_Pass;
	}
}