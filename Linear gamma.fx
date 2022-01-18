#include "ReShadeUI.fxh"

uniform int Gamma_type < __UNIFORM_COMBO_INT1
    ui_items = "sRGB -> linear RGB\0linear RGB -> sRGB\0Rec.(2020/601/709) RGB -> linear RGB\0linear RGB -> Rec.(2020/601/709) RGB\0gamma=2.2 -> linear RGB\0linear RGB -> gamma=2.2\0gamma=2.6 -> linear RGB\0linear RGB -> gamma=2.6\0gamma=2.4 -> linear RGB\0linear RGB -> gamma=2.4\0";
> = 0;

uniform int Gamma_type_2 < __UNIFORM_COMBO_INT1
    ui_items = "sRGB -> linear RGB\0linear RGB -> sRGB\0Rec.(2020/601/709) RGB -> linear RGB\0linear RGB -> Rec.(2020/601/709) RGB\0gamma=2.2 -> linear RGB\0linear RGB -> gamma=2.2\0gamma=2.6 -> linear RGB\0linear RGB -> gamma=2.6\0gamma=2.4 -> linear RGB\0linear RGB -> gamma=2.4\0";
	ui_tooltip = "Transfer function for the second instance of the shader, if enabled.";
> = 1;


#include "ReShade.fxh"

#include "DrawText_mod.fxh"

#define rcpTwoFour 1.0/2.4
#define rcpOFiveFive 1.0/1.055
#define rcpTwelveNineTwo 1.0/12.92
#define recAlpha 1.09929682680944
#define rcpRecAlpha 1.0/1.09929682680944
#define recBeta 0.018053968510807
#define recBetaLin 0.004011993002402
#define rcpFourFive 1.0/4.5
#define rcpTxFourFive 10.0/4.5
#define invTwoTwo 5.0/11.0
#define invTwoSix 5.0/13.0


float3 transferrer(float3 c0, int mode){

float3 c1=c0;

[branch]if (mode==1){ //sRGB transfer
    c1.rgb=(c0.rgb> 0.00313066844250063)?1.055 * pow(c0.rgb,rcpTwoFour) - 0.055:12.92 *c0.rgb;
}else if(mode==7){
    c1.rgb=pow(c0.rgb,invTwoSix);
}else if(mode==8){
    c1.rgb=pow(c0.rgb,2.4);
}else if(mode==9){
    c1.rgb=pow(c0.rgb,rcpTwoFour);
}else if (mode==5){
    c1.rgb=pow(c0.rgb,invTwoTwo);
}else if(mode==3){
    c1.rgb=(c0.rgb< recBeta)?4.5*c0.rgb:recAlpha*pow(c0.rgb,0.45)-(recAlpha-1);
}else if(mode==0){
    c1.rgb=(c0.rgb > 0.0404482362771082 )?pow(abs((c0.rgb+0.055)*rcpOFiveFive),2.4):c0.rgb*rcpTwelveNineTwo;
}else if(mode==6){
    c1.rgb=pow(c0.rgb,2.6);
}else if(mode==4){
    c1.rgb=pow(c0.rgb,2.2);
}else if(mode==2){
    c1.rgb=(c0.rgb < recBetaLin )?rcpFourFive*c0.rgb:pow(-1*(rcpRecAlpha*(1-recAlpha-c0.rgb)),rcpTxFourFive);
}

return c1;

}


float4 LinearGammaPass(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{

float4 c0 = tex2D(ReShade::BackBuffer, texcoord);
float4 c1 = c0;

c1.rgb=transferrer(c0.rgb, Gamma_type);

return c1;

}

float4 LinearGammaPass2(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{

float4 c0 = tex2D(ReShade::BackBuffer, texcoord);
float4 c1 = c0;

c1.rgb=transferrer(c0.rgb, Gamma_type_2);

return c1;

}

technique Linear_Gamma
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LinearGammaPass;
	}
}

technique Linear_Gamma_2
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LinearGammaPass2;
	}
}