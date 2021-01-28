sampler s0 : register(s0); 

float4 p0 : register(c0); 
float4 p1 : register(c1); 
 
#define width (p0[0]) 
#define height (p0[1]) 
#define counter (p0[2]) 
#define clock (p0[3]) 
#define one_over_width (p1[0]) 
#define one_over_height (p1[1]) 

#define PI acos(-1) 

#define yInterval 0
#define xInterval 0

#define split 0
#define flip_split 0
#define split_position 0.5

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 

float yInt=yInterval*one_over_height;
float xInt=xInterval*one_over_width;

float Split=split;
float Split_position=split_position;
float Flip_split=flip_split;

float4 c0 = tex2D( s0, tex ); 

float4 c1 = c0;
 
float ceny=tex.y;
float cenx=tex.x;
 
ceny=(yInterval>0)?floor(tex.y/yInt)*yInt+(yInt*0.5):ceny;

cenx=(xInterval>0)?floor(tex.x/xInt)*xInt+(xInt*0.5):cenx;

c1= tex2D( s0,float2(cenx,ceny));

float4 c2=(tex.x>=Split_position*Split)?c1:c0;
float4 c3=(tex.x<=Split_position*Split)?c1:c0;

float4 c4=(Flip_split*Split==1)?c3:c2;

float divLine = abs(tex.x - Split_position) < one_over_width;
c4 =(Split==0)?c4: c4*(1.0 - divLine); //invert divline

return c4;
}
