sampler s0 : register(s0);
float4 p0 :  register(c0);
float4 p1 :  register(c1);
float4 p2 :  register(c2);
float2 p3 :  register(c3);

#define width   (p0[0])
#define height  (p0[1])
#define counter (p0[2])
#define clock   (p0[3])
#define one_over_width  (p1[0])
#define one_over_height (p1[1])


float3 rgb2hsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
 
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}


float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
//Source: http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl

///////////////////EDIT HERE//////////////////////////////////////////////////

#define debug p2.x //0-13; 0-greyscale, 1-red, 2-orange/brown, 3-yellow, 4-chartreuse/lime, 5-green, 6-spring green, 7-cyan, 8-azure/sky blue, 9-blue, 10-violet/purple, 11-magenta/pink, 12-reddish pink, 13-Custom

#define split p2.y
#define flip_split p2.z
#define split_position  p2.w

///////////////////////////////////////////////////////////////////////////////

float4 main(float2 tex : TEXCOORD0) : COLOR {

float4 c0=tex2D(s0, tex);
float4 c1=c0;

int Debug=round(debug);
float Split=split;
float Split_position=split_position;
float Flip_split=flip_split;

float Cust_from=p3.x/360.0;
float Cust_to=p3.y/360.0;

float3 c0_hsv=rgb2hsv(c0.rgb);

int hue=floor(c0_hsv.x*3600);

int grey=(((c0.r==c0.g)&&(c0.g==c0.b))||(c0_hsv.y==0))?1:0;

[flatten]if(Debug==0){
c1.rgb=(grey==1)?c0.rgb:0;
}else if(Debug==1){
c1.rgb=((hue>=3525)||(((hue>=0) && (hue<75))&&(grey==0)))?c0.rgb:c0_hsv.z;
}else if(Debug==2){
c1.rgb=((hue>=75) && (hue<375))?c0.rgb:c0_hsv.z;
}else if(Debug==3){
c1.rgb=((hue>=375) && (hue<675))?c0.rgb:c0_hsv.z;
}else if(Debug==4){
c1.rgb=((hue>=675) && (hue<975))?c0.rgb:c0_hsv.z;
}else if(Debug==5){
c1.rgb=((hue>=975) && (hue<1275))?c0.rgb:c0_hsv.z;
}else if(Debug==6){
c1.rgb=((hue>=1275) && (hue<1575))?c0.rgb:c0_hsv.z;
}else if(Debug==7){
c1.rgb=((hue>=1575) && (hue<1875))?c0.rgb:c0_hsv.z;
}else if(Debug==8){
c1.rgb=((hue>=1875) && (hue<2175))?c0.rgb:c0_hsv.z;
}else if(Debug==9){
c1.rgb=((hue>=2175) && (hue<2475))?c0.rgb:c0_hsv.z;
}else if(Debug==10){
c1.rgb=((hue>=2475) && (hue<3075))?c0.rgb:c0_hsv.z;
}else if(Debug==11){
c1.rgb=((hue>=3075) && (hue<3375))?c0.rgb:c0_hsv.z;
}else if(Debug==12){
c1.rgb=((hue>=3375) && (hue<3525))?c0.rgb:c0_hsv.z;
}else if(Debug==13){
	[flatten]if(Cust_from>Cust_to){
		[flatten]if(((c0_hsv.x>=Cust_from)&&(c0_hsv.x<=1))||((c0_hsv.x>=0)&&(c0_hsv.x<=Cust_to))){
		c1.rgb=c0.rgb;
		}else{
		c1.rgb=c0_hsv.z;
		}
	}else{
		[flatten]if((c0_hsv.x>=Cust_from)&&(c0_hsv.x<=Cust_to)){
		c1.rgb=c0.rgb;
		}else{
		c1.rgb=c0_hsv.z;
		}
	}
}


float4 c2=(tex.x>=Split_position*Split)?c1:c0;
float4 c3=(tex.x<=Split_position*Split)?c1:c0;

float4 c4=(Flip_split*Split==1)?c3:c2;

float divLine = abs(tex.x - Split_position) < one_over_width;
c4 =(Split==0)?c4: c4*(1.0 - divLine); //invert divline

return c4;
}