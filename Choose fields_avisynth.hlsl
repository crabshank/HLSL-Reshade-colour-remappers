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

#define yInterval p2.x //No. of pixels high per line
#define yOffset p2.y

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 

float4 c0 = tex2D( s0, tex ); 

float dy = one_over_height;
float yOff=yOffset;
float yInt=yInterval*dy;

if(fmod(round(floor(tex.y/yInt)+yOff), 2)!=0){
c0.rgb =0;
}

return c0;
}
