sampler s0 : register(s0); 

float4 p0 : register(c0); 
float4 p1 : register(c1); 
float4 p2 : register(c2); 

#define width (p0[0]) 
#define height (p0[1]) 
#define counter (p0[2]) 
#define clock (p0[3]) 
#define one_over_width (p1[0]) 
#define one_over_height (p1[1]) 

#define PI acos(-1) 

#define Saturation p2.x // 0 to 1
#define Turn_black p2.y // 0 or 1

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 

float saturation=saturate(Saturation);
int turn_black=round(Turn_black);

float4 c0=tex2D( s0, tex );
float mx=max(c0.r,max(c0.g,c0.b));
float mn=min(c0.r,min(c0.g,c0.b));
float sat=(mx==0)?0:(mx-mn)/mx;
[flatten]if(sat<=saturation){
c0.rgb=(turn_black==1)?0:1;
}
return c0;

}