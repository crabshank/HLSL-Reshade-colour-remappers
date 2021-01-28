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

float t=frac(acos(p.x/p.y)+sin(p.x)*r.y+cos(p.y)*r.x+p.x*p.y*r.y);

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

#define debug p2.w //0, 1 - show odd fields, 2 - even
#define yInterval p2.x //No. of pixels
#define yOffset p2.y
#define fieldShear p2.z ////No. of pixels
//#define oddEven 0 //Field to shear to the right: 0 - Even, 1 - odd
#define debugFade 0.5

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
float fieldShr=fieldShear;
float dbgFde = debugFade;
float OdEv=round(random(float2((tex.x+width*dy)*max(max(c0.r,c0.g),c0.b),(tex.y+height*dx)*max(max(c0.r,c0.g),c0.b))));

float Split=split;
float Split_position=split_position;
float Flip_split=flip_split;

float4 g0=c0;
float4 g1=c0;
float4 g2=c0;
float4 g3=c0;
float4 g4=c0;
float4 g5=c0;
float4 g6=c0;
float4 g7=c0;
float4 g8=c0;
float4 g9=c0;

g0=(debug==1)?dbgFde*c1:c1; //fmod(floor(tex.y/yInt)+yOff, 2)==0
g1=((debug!=1 && debug!=2) && OdEv==1)?tex2D( s0,float2(tex.x-fieldShr*dx,tex.y)):c1;
g2=((debug!=1 && debug!=2) && OdEv!=1)?tex2D( s0,float2(tex.x+fieldShr*dx,tex.y)):c1;

g3=(debug==2)?dbgFde*c1:c1; //fmod(floor(tex.y/yInt)+yOff, 2)!=0
g4=((debug!=1 && debug!=2) && OdEv==1)?tex2D( s0,float2(tex.x+fieldShr*dx,tex.y)):c1;
g5=((debug!=1 && debug!=2) && OdEv!=1)? tex2D( s0,float2(tex.x-fieldShr*dx,tex.y)):c1;

g6=(OdEv==1)?g1:g2;
g7=(debug!=1 && debug!=2)?g6:g0;

g8=(OdEv==1)?g4:g5;
g9=(debug!=1 && debug!=2)?g8:g3;

c1=(fmod(floor(tex.y/yInt)+yOff, 2)==0)?g7:g9;


float4 c2=(tex.x>=Split_position*Split)?c1:c0;
float4 c3=(tex.x<=Split_position*Split)?c1:c0;

float4 c4=(Flip_split*Split==1)?c3:c2;

float divLine = abs(tex.x - Split_position) < one_over_width;
c4 =(Split==0)?c4: c4*(1.0 - divLine); //invert divline

return c4;
}