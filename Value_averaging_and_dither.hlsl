// $MinimumShaderProfile: ps_3_0
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

static float d_x_b[2]={0,1};static float d_y_b[2]={0,1};
 
#define dither_points 7

static float2 d[dither_points] = {
0,0,
1,0,
64.90915,63.75,
131.4898,127.5,
194.1036,191.25,
254,255,
255,255
};

float dither_map(float dither){int i=0;int exact=0;[unroll(dither_points)]for(i=0;i<dither_points;i++){[branch]if(d[i][0]/255==dither) {dither=d[i][1]/255;exact=1;i=dither_points-1;}else{if(d[i][0]/255<dither&&d[i][0]/255>=d_x_b[0]){d_x_b[0]=d[i][0]/255;d_y_b[0]=d[i][1]/255;} if(d[i][0]/255<=d_x_b[1]&&dither<d[i][0]/255){d_x_b[1]=d[i][0]/255;d_y_b[1]=d[i][1]/255;}}} if(exact==0){dither=d_y_b[0]+(dither-d_x_b[0])*((d_y_b[1]-d_y_b[0])/(d_x_b[1]-d_x_b[0]));}return dither;} 

float random( float2 p ){
	// We need irrationals for pseudo randomness.
	// Most (all?) known transcendental numbers will (generally) work.
	const float2 r = float2(
	23.1406926327792690,  // e^pi (Gelfond's constant)
	 2.6651441426902251); // 2^sqrt(2) (Gelfond-Schneider constant)

	float t=frac(acos(min(p.x,p.y)/max(p.x,p.y))+sin(p.x)*r.y+cos(p.y)*r.x+p.x*p.y*r.y);

	t= frac((800*cos(t/20)+1400)*t);  
	t= frac(pow( frac((0.01*t+sin(500*t*t))+tan(t*500)*500),2));

	float rMap =3.98;
	float tOld=t;
	int i=0;

	[unroll(100)]for (i=0;i<100;i++){
	tOld=rMap*tOld*(1-tOld);
	}
	 
	 float w = frac(10000*tOld+0.597*tOld);


	return dither_map(w);

}

float grey_dither(float color,float2 tex,float sdv, float lrp){

	float rand=random(float2((tex.x+width*one_over_height)*color,(tex.y+height*one_over_width)*color));

	float sAB=sdv*sqrt(12)*0.5;	
	float randm=sAB*(2*rand-1)*-1;

	return randm;

}

///////////////////EDIT HERE//////////////////////////////////////////////////

#define std_dev 0.08 //Change standard deviation value of dither
#define lerper 0.3
#define dxy 3 //No. of adjacent pixels to include in the sample

///////////////////////////////////////////////////////////////////////////////

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 

float4 c0 = tex2D( s0, tex ); 

float3 c0_hsv=rgb2hsv(c0.rgb);
 
int x=0;
int y=0;

float dx = one_over_width;
float dy = one_over_height;
float std_dev1=std_dev;
float lerper1=lerper;
int dxy1 = dxy;

float count=0;
float accm=0;

	for (x=-1*dxy1; x<=dxy1; x+=1){
	for (y=-1*dxy1; y<=dxy1; y+=1){
	
		float4 current=tex2D( s0,float2(tex.x+float(x)*dx,tex.y+float(y)*dy));
		float3 currMax=max(current.r,max(current.g, current.b));
		accm+=currMax;
		count+=1.0;
	}
	}

	float nw_v=accm/count;
	float nw_lerp=lerper1;
	[branch]if(std_dev1!=0){
		nw_lerp+=grey_dither(nw_v,tex,std_dev1,lerper1);
		nw_lerp=saturate(nw_lerp);
	}
	float lrp_v=lerp(c0_hsv.z,nw_v,nw_lerp);
	float3 nw_hsv=float3(c0_hsv.xy,lrp_v);
	float3 nw_rgb=hsv2rgb(nw_hsv);
	float4 c1=float4(nw_rgb,c0.w);
	return c1;
}
