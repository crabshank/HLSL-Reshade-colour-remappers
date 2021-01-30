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

#define debug p2.w //0, 1 - show odd fields, 2 - even
#define yInterval p2.x //No. of pixels
#define yOffset p2.y
#define fieldShift p2.z //No. of pixels

#define debugFade 0

#define split 0
#define flip_split 0
#define split_position 0.5

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 

float4 c0 = tex2D( s0, tex ); 

float4 c1 =c0;
 
float dx = one_over_width;
float dy = one_over_height;
float yOff=yOffset;
float yInt=yInterval*dy;
float fieldShft=fieldShift;
float dbgFde = debugFade;

float Split=split;
float Split_position=split_position;
float Flip_split=flip_split;

float4 g1=tex2D( s0,float2(tex.x+fieldShft*dx,tex.y));


[flatten]if(debug==1){

if(fmod(floor(tex.y/yInt)+yOff, 2)==0){
c1 =dbgFde*c0;
return c1;
}

}else if (debug==2){

if(fmod(floor(tex.y/yInt)+yOff, 2)!=0){
c1 =dbgFde*c0;
return c1;
}
}
else{
c1=(fmod(floor(tex.y/yInt)+yOff, 2)==0)?c1=g1:c0;
}



float4 c2=(tex.x>=Split_position*Split)?c1:c0;
float4 c3=(tex.x<=Split_position*Split)?c1:c0;

float4 c4=(Flip_split*Split==1)?c3:c2;

float divLine = abs(tex.x - Split_position) < one_over_width;
c4 =(Split==0)?c4: c4*(1.0 - divLine); //invert divline

return c4;
}
