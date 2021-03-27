sampler s0 : register(s0);
float4 p0 :  register(c0);
float4 p1 :  register(c1);
float2 p2 :  register(c2);

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

#define outVal p2.x

#define greyCol p2.y

float4 main(float2 tex : TEXCOORD0) : COLOR {

float4 c0=tex2D(s0, tex);
float4 c1=c0;

float oValue=saturate(outVal);
int greyColour=round(p2.y);
float hueCol;
float3 c0_hsv=rgb2hsv(c0.rgb);

int hue=floor(c0_hsv.x*3600);

int grey=(((c0.r==c0.g)&&(c0.g==c0.b))||(c0_hsv.y==0))?1:0;

[flatten]if(grey==0){

if((hue>=3525)||(((hue>=0) && (hue<75)))){
hueCol=0.0;
}else if((hue>=75) && (hue<375)){
hueCol=30.0;
}else if((hue>=375) && (hue<675)){
hueCol=60.0;
}else if((hue>=675) && (hue<975)){
hueCol=90.0;
}else if((hue>=975) && (hue<1275)){
hueCol=120.0;
}else if((hue>=1275) && (hue<1575)){
hueCol=150.0;
}else if((hue>=1575) && (hue<1875)){
hueCol=180.0;
}else if((hue>=1875) && (hue<2175)){
hueCol=210.0;
}else if((hue>=2175) && (hue<2475)){
hueCol=240.0;
}else if((hue>=2475) && (hue<3075)){
hueCol=270.0;
}else if((hue>=3075) && (hue<3375)){
hueCol=330.0;
}else if((hue>=3375) && (hue<3525)){
hueCol=345.0;
}

c1.rgb=hsv2rgb(float3(hueCol/360.0,1,oValue));

}else{
	
	float greyOut;
	
	[flatten]if(greyColour==2){
		greyOut=1;
	}else if(greyColour==0){
		greyOut=0;
	}else{
		greyOut=0.5;
	}
	
	c1.rgb=hsv2rgb(float3(0.0,0.0,greyOut));
	
}

return c1;
}