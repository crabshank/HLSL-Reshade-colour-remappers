sampler s0 : register(s0); 

float4 p0 : register(c0); 
float4 p1 : register(c1); 
float2 p2 : register(c2); 

#define width (p0[0]) 
#define height (p0[1]) 
#define counter (p0[2]) 
#define clock (p0[3]) 
#define one_over_width (p1[0]) 
#define one_over_height (p1[1]) 

#define PI acos(-1) 

#define sat_lo p2.x //Blacken pixels with saturation < Sat_lo
#define sat_hi p2.y //Make pixels with saturation >=Sat_lo and <Sat_hi grey

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 
float Sat_lo=sat_lo;
float Sat_hi=sat_hi;

float4 c0=tex2D( s0, tex );
float mx=max(c0.r,max(c0.g,c0.b));
float mn=min(c0.r,min(c0.g,c0.b));
float chr=mx-mn;
float sat=(mx==0)?0:(chr)/mx;

c0.rgb=(sat<Sat_lo)?0:((sat<Sat_hi)?0.5:c0.rgb);

return c0;
}