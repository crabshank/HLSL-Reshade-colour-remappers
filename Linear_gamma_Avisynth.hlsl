sampler s0 : register(s0); 

float4 p0 : register(c0); 
float4 p1 : register(c1); 
float p2 : register(c2); 

#define width (p0[0]) 
#define height (p0[1]) 
#define counter (p0[2]) 
#define clock (p0[3]) 
#define one_over_width (p1[0]) 
#define one_over_height (p1[1]) 

#define PI acos(-1) 

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

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 
	int Linear=round(p2.x);
	
	float4 c0 = tex2D(s0, tex);
	float4 c1 = c0;
	
[branch]if (Linear==1){ //sRGB transfer
    c1.rgb=(c0.rgb> 0.00313066844250063)?1.055 * pow(c0.rgb,rcpTwoFour) - 0.055:12.92 *c0.rgb;
}else if(Linear==7){
    c1.rgb=pow(c0.rgb,invTwoSix);
}else if(Linear==8){
    c1.rgb=pow(c0.rgb,2.4);
}else if(Linear==9){
    c1.rgb=pow(c0.rgb,rcpTwoFour);
}else if (Linear==5){
    c1.rgb=pow(c0.rgb,invTwoTwo);
}else if(Linear==3){
    c1.rgb=(c0.rgb< recBeta)?4.5*c0.rgb:recAlpha*pow(c0.rgb,0.45)-(recAlpha-1);
}else if(Linear==0){
    c1.rgb=(c0.rgb > 0.0404482362771082 )?pow(abs((c0.rgb+0.055)*rcpOFiveFive),2.4):c0.rgb*rcpTwelveNineTwo;
}else if(Linear==6){
    c1.rgb=pow(c0.rgb,2.6);
}else if(Linear==4){
    c1.rgb=pow(c0.rgb,2.2);
}else if(Linear==2){
    c1.rgb=(c0.rgb < recBetaLin )?rcpFourFive*c0.rgb:pow(-1*(rcpRecAlpha*(1-recAlpha-c0.rgb)),rcpTxFourFive);
}

return c1;

}