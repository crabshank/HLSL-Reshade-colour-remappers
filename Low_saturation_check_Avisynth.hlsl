sampler s0 : register(s0); 

float4 p0 : register(c0); 
float4 p1 : register(c1); 
float3 p2 : register(c2); 

#define width (p0[0]) 
#define height (p0[1]) 
#define counter (p0[2]) 
#define clock (p0[3]) 
#define one_over_width (p1[0]) 
#define one_over_height (p1[1]) 

#define PI acos(-1) 

#define Grey_colour p2.x // 0 to 2 (Black, Mid_grey, White)
#define Metric p2.y // 0 to 1 (saturation, min(chroma,saturation))
#define Greyness p2.z // 0 to 1 [Blacken/whiten pixels with: saturation<=Greyness OR min(chroma,saturation)<=Greyness]

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 


int grey_colour=round(Grey_colour);
int metric=round(Metric);
float greyness=saturate(Greyness);

float4 c0=tex2D( s0, tex );

float mx=max(c0.r,max(c0.g,c0.b));
float mn=min(c0.r,min(c0.g,c0.b));
float chr=mx-mn;
float sat=(mx==0)?0:(chr)/mx;
float greyOut=0;

[flatten]if(grey_colour==2){
					greyOut=1;
				}else if(grey_colour==1){
					greyOut=0.5;
				}

[flatten]if(metric==1){
	c0.rgb=(min(chr,sat)<=greyness)?greyOut:c0.rgb;
}else{
	c0.rgb=(sat<=greyness)?greyOut:c0.rgb;
}

return c0;

}