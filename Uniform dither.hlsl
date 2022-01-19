sampler s0 : register(s0);
float4 p0 :  register(c0);
float4 p1 :  register(c1);

#define width   (p0[0])
#define height  (p0[1])
#define counter (p0[2])
#define clock   (p0[3])
#define one_over_width  (p1[0])
#define one_over_height (p1[1])

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


float random( float2 p )
{
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

float grey_dither(float color,float2 tex,float rnd,float sdv){

float rand=random(float2((tex.x+width*one_over_height)*color,(tex.y+height*one_over_width)*color));
float randm=rnd*-1*((rand*-4)+1); // averages to color + rnd

color=(rnd!=0)?color+(randm/255):color;

float sAB=sdv*sqrt(12)*0.5;
randm=sAB*(2*rand-1)*-1;
color=(sdv!=0)?color+(randm/255):color;

return color;

}

///////////////// CHANGE HERE! ////////////////////////////////////////////////////////////////////////////////////////////////////

#define greyDither_Amnt 0 //Change average value by specified amount

#define greyDither_Sdv 4.3 //Change standard deviation by specified amount

#define darkDither 0.15 // 0 (dither all brightnesses equally), as increases: favour dithering dark areas
 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 
	float4 c0 = tex2D(s0, tex);

	float c0Max=max(c0.r,max(c0.g,c0.b));
	float4 c1 = c0;

	float greyDitherSdv=greyDither_Sdv;
	float greyDitherAmnt=greyDither_Amnt;
	float drk=darkDither;

	float dth=saturate(grey_dither(c0Max,tex,greyDitherAmnt,greyDitherSdv));
	c1.rgb =(c0Max==0)?dth:dth*(c1.rgb/c0Max);

	float c1Max=max(c1.r,max(c1.g,c1.b));

	c1.rgb =(drk>0)?lerp(c1.rgb,c0,1-pow(c1Max,drk)):c1.rgb;

	return c1;

}