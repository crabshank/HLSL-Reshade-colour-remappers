sampler s0 : register(s0); 

float4 p0 : register(c0); 
float4 p1 : register(c1); 
float2 p2 : register(c2); 
float3 p3 : register(c3); 

#define width (p0[0]) 
#define height (p0[1]) 
#define counter (p0[2]) 
#define clock (p0[3]) 
#define one_over_width (p1[0]) 
#define one_over_height (p1[1]) 

#define PI acos(-1) 


float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 

	float Split=round(p3.x);
	float Split_position=p3.y;
	float Flip_split=round(p3.z);
	
	float fieldShftX=round(p2.x);
	float fieldShftY=round(p2.y);

float4 c0 = tex2D( s0, tex ); 

float4 c1 =c0;
 
float dx = one_over_width;
float dy = one_over_height;


float4 g1=tex2D( s0,float2(tex.x+fieldShftX*dx,tex.y+fieldShftY*dy));

float g1Max=max(g1.r,max(g1.g,g1.b));
float c0Max=max(c0.r,max(c0.g,c0.b));

c1.rgb=lerp(g1.rgb,c1.rgb,2*abs(c0Max-0.5));

float4 c2=(tex.x>=Split_position*Split)?c1:c0;
float4 c3=(tex.x<=Split_position*Split)?c1:c0;

float4 c4=(Flip_split*Split==1)?c3:c2;

float divLine = abs(tex.x - Split_position) < one_over_width;
c4 =(Split==0)?c4: c4*(1.0 - divLine); //invert divline

return c4;
}
