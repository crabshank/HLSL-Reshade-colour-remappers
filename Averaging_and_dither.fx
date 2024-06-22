#include "ReShadeUI.fxh"

uniform int dxy < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 10;
	ui_tooltip = "No. of adjacent pixels to include in the sample.";
> = 3;

uniform float lerper_v < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Value averaging";
> = 0.659;

uniform float lerper_s  < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Saturation averaging";
> = 1;

uniform float std_dev < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max =1.0;
	ui_tooltip = "Change standard deviation value of dither (applies to value only)";
> = 0;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float random( float2 p )
{
	// We need irrationals for pseudo randomness.
	// Most (all?) known transcendental numbers will (generally) work.
	const float2 r = float2(
	23.1406926327792690,  // e^pi (Gelfond's constant)
	 2.6651441426902251); // 2^sqrt(2) (Gelfond-Schneider constant)

	float t=frac(acos(p.x/p.y)+sin(p.x)*r.y+cos(p.y)*r.x+p.x*p.y*r.y);

	t= frac((800*cos(t/20)+1400)*t);  
	t= frac(pow( frac((0.01*t+sin(500*t*t))+tan(t*500)*500),2));

	float rMap =3.98;
	float tOld=t;
	int k=0;

	for (k=0;k<100;k++){
	tOld=rMap*tOld*(1-tOld);
	}
	 
	 float w = frac(10000*tOld+0.597*tOld);

	#define dither_points 7
	float2 d[dither_points] = {
	float2(0,0),
	float2(1,0),
	float2(64.90915,63.75),
	float2(131.4898,127.5),
	float2(194.1036,191.25),
	float2(254,255),
	float2(255,255)
	};


	float2 d_x_b=float2(0,1);float2 d_y_b=float2(0,1);
	float dither=w;
	int i=0; int exact=0; 
	for(i=0;i<dither_points;i++){
	[branch]if(d[i].x/255==dither) {dither=d[i].y/255;exact=1;i=dither_points-1;}else{if(d[i].x/255<dither&&d[i].x/255>=d_x_b.x){d_x_b.x=d[i].x/255;d_y_b.x=d[i].y/255;} if(d[i].x/255<=d_x_b.y&&dither<d[i].x/255){d_x_b.y=d[i].x/255;d_y_b.y=d[i].y/255;}}} if(exact==0){dither=d_y_b.x+(dither-d_x_b.x)*((d_y_b.y-d_y_b.x)/(d_x_b.y-d_x_b.x));};i=0;exact=0;

	return dither;

}


float grey_dither(float color,float2 tex,float sdv, float lrp){
tex.x=min(tex.x,abs(0.5-tex.x*0.5));
tex.y=max(tex.y,abs(0.5-tex.y*0.5));
float2 cxy=float2((0.5*(tex.x+color)+max(tex.x,color))*0.5,(0.5*(tex.y+color)+max(tex.y,color))*0.5);
float rand=random(cxy);

float sAB=sdv*sqrt(12)*0.5;	
float randm=sAB*(2*rand-1)*-1;

return randm;
}


float4 PS_Averaging_dither(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target{

	float4 c0=tex2D(ReShade::BackBuffer, texcoord);
	float3 c0_hsv=rgb2hsv(c0.rgb);

	int x=0;
	int y=0;
	float count=0;
	float accm_s=0;
	float accm_v=0;

	for (x=-1*dxy; x<=dxy; x+=1){
	for (y=-1*dxy; y<=dxy; y+=1){
	
		float4 current=tex2Dlod(ReShade::BackBuffer, float4(texcoord.x+float(x)*BUFFER_RCP_WIDTH, texcoord.y+float(y)*BUFFER_RCP_HEIGHT, 0, 0));
		float mx=max(current.r,max(current.g, current.b));
		float mn=min(current.r,min(current.g, current.b));
		float sat=(mx==0)?0:(mx-mn)/mx;
		accm_s+=sat;
		accm_v+=mx;
		count+=1.0;
	}
	}
	
	float nw_s=accm_s/count;
	float lrp_s=lerp(c0_hsv.y,nw_s,lerper_s);
	
	float nw_v=accm_v/count;
	float nw_lerp=lerper_v;
	[branch]if(std_dev!=0){
		nw_lerp+=grey_dither(nw_v,texcoord,std_dev,lerper_v);
		nw_lerp=saturate(nw_lerp);
	}
	float lrp_v=lerp(c0_hsv.z,nw_v,nw_lerp);
	float3 nw_hsv=float3(c0_hsv.x,lrp_s,lrp_v);
	float3 nw_rgb=hsv2rgb(nw_hsv);
	float4 c1=float4(nw_rgb,c0.w);
	return c1;

}

technique Averaging_and_dither {
	pass Averaging_dither {
		VertexShader=PostProcessVS;
		PixelShader=PS_Averaging_dither;
	}
}
