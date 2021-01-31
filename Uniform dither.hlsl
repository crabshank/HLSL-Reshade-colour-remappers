sampler s0 : register(s0);
float4 p0 :  register(c0);
float4 p1 :  register(c1);

#define width   (p0[0])
#define height  (p0[1])
#define counter (p0[2])
#define clock   (p0[3])
#define one_over_width  (p1[0])
#define one_over_height (p1[1])

#define rcptwoFiveFive 1.0/255.0
#define rcpTwoFour 1.0/2.4
#define rcpOFiveFive 1.0/1.055
#define rcpTwelveNineTwo 1.0/12.92
#define recAlpha 1.09929682680944
#define rcpRecAlpha 1.0/1.09929682680944
#define recBeta 0.018053968510807
#define recBetaLin 0.004011993002402
#define rcpFourFive 1.0/4.5
#define rcpTxFourFive 10.0/4.5
#define invTwoTwo 5.0/11.0
#define invTwoSix 5.0/13.0 

float3 rgb2LinRGB(float3 rgb,int mode){

	  float3 rgbLin;

[branch]if ((mode==0)||(mode==6)){ //sRGB transfer
    rgbLin=(rgb > 0.0404482362771082 )?pow(abs((rgb+0.055)*rcpOFiveFive),2.4):rgb*rcpTwelveNineTwo;
}else if ((mode==5)||(mode==10)){ //DCI-P3
    rgbLin=pow(rgb,2.6);
}else if (mode==7){ //Original NTSC
    rgbLin=pow(rgb,2.2);
}else{ //Rec transfer
    rgbLin=(rgb < recBetaLin )?rcpFourFive*rgb:pow(-1*(rcpRecAlpha*(1-recAlpha-rgb)),rcpTxFourFive);
}


return rgbLin;
}

float3 linRGB2rgb(float3 rgb_i,int mode){

float3 RGB=rgb_i;

[branch]if ((mode==0)||(mode==6)){ //sRGB transfer
      RGB=(rgb_i> 0.00313066844250063)?1.055 * pow(rgb_i,rcpTwoFour) - 0.055:12.92 *rgb_i;
}else if ((mode==5)||(mode==10)){ //DCI-P3
      RGB=pow(rgb_i,invTwoSix);
}else if (mode==7){ //Original NTSC - Source: 47 CFR, Section 73.682 - TV transmission standards
      RGB=pow(rgb_i,invTwoTwo);
}else{ //Rec transfer
      RGB=(rgb_i< recBeta)?4.5*rgb_i:recAlpha*pow(rgb_i,0.45)-(recAlpha-1);
}

return RGB;
}


float3 LinRGB2XYZ(float3 rgbLin,int mode){

float3 v1;
float3 v2;
float3 v3;

[branch]if (mode==1){ //Rec 601 NTSC
    v1.x=0.3935891;
    v1.y=0.3652497;
    v1.z=0.1916313;
    v2.x=0.2124132;
    v2.y=0.7010437;
    v2.z=0.0865432;
    v3.x=0.0187423;
    v3.y=0.1119313;
    v3.z=0.9581563;
}else if (mode==2){ //Rec 601 PAL
    v1.x=0.430619;
    v1.y=0.3415419;
    v1.z=0.1783091;
    v2.x=0.2220379;
    v2.y=0.7066384;
    v2.z=0.0713236;
    v3.x=0.0201853;
    v3.y=0.1295504;
    v3.z=0.9390944;
}else if(mode==5){ //DCI-P3
    v1.x=0.445169815564552;
    v1.y=0.277134409206778;
    v1.z=0.172282669815565;
    v2.x=0.209491677912731;
    v2.y=0.721595254161044;
    v2.z=0.068913067926226;
    v3.x=0;
    v3.y=0.047060560053981;
    v3.z=0.907355394361973;
}else if(mode==6){
    v1.x=0.48663265;
    v1.y=0.2656631625;
    v1.z=0.1981741875;
    v2.x=0.2290036;
    v2.y=0.691726725;
    v2.z=0.079269675;
    v3.x=0;
    v3.y=0.0451126125;
    v3.z=1.0437173875;
}else if (mode==4){ //Rec 2020
    v1.x=0.637010191411101;
    v1.y=0.144615027396969;
    v1.z=0.16884478119193;
    v2.x=0.26272171736164;
    v2.y=0.677989275502262;
    v2.z=0.059289007136098;
    v3.x=0;
    v3.y=0.028072328847647;
    v3.z=1.06075767115235;
}else if (mode==7){ //Original NTSC
    v1.x=0.6069928;
    v1.y=0.1734485;
    v1.z=0.2005713;
    v2.x=0.2989666;
    v2.y=0.5864212;
    v2.z=0.1146122;
    v3.x=0;
    v3.y=0.0660756;
    v3.z=1.1174687;
}else if (mode==8){ //Rec 601 D93
    v1.x=0.3275085;
    v1.y=0.3684739;
    v1.z=0.2568954;
    v2.x=0.1767506;
    v2.y=0.7072321;
    v2.z=0.1160173;
    v3.x=0.0155956;
    v3.y=0.1129194;
    v3.z=1.2844772;
}else if (mode==9){ //Rec 709 D93
    v1.x=0.3490195;
    v1.y=0.3615584;
    v1.z=0.2422998;
    v2.x=0.1799632;
    v2.y=0.7231169;
    v2.z=0.0969199;
    v3.x=0.0163603;
    v3.y=0.1205195;
    v3.z=1.2761125;
}else if (mode==10){ //DCI-P3 D60/ACES
    v1.x=0.504949534191744;
    v1.y=0.264681488895262;
    v1.z=0.18301505148284;
    v2.x=0.23762331020788;
    v2.y=0.689170669198985;
    v2.z=0.073206020593136;
    v3.x=0;
    v3.y=0.04494591320863;
    v3.z=0.963879271142956;
}else{ //sRGB - Rec 709
    v1.x=0.4124564;
    v1.y=0.3575761;
    v1.z=0.1804375;
    v2.x=0.2126729;
    v2.y=0.7151522;
    v2.z=0.072175;
    v3.x=0.0193339;
    v3.y=0.119192;
    v3.z=0.9503041;
}

		return float3(dot(v1, rgbLin), dot(v2, rgbLin), dot(v3, rgbLin));

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
 
#define MODE 1 // 0 - sRGB | 1 - Rec 601 NTSC | 2 - Rec. 601 PAL | 3 - Rec. 709 | 4 - Rec.2020 | 5 - DCI-P3 | 6 - Display P3 | 7 - Orginal NTSC (47 CFR ยง 73.682 - TV transmission standards) | 8 - Rec. 601 D93 | 9 - Rec. 709 D93 | 10 - DCI-P3 (D60/ACES)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 
	float4 c0 = tex2D(s0, tex);
	int mode = MODE;
	c0.rgb=rgb2LinRGB(c0.rgb,mode);
	float4 c0OG_lin = c0;
	float c0Max=max(c0.r,max(c0.g,c0.b));
	float4 c1 = c0;

	float greyDitherSdv=greyDither_Sdv;
	float greyDitherAmnt=greyDither_Amnt;
	float drk=darkDither;

c1.rgb =saturate(grey_dither(c0Max,tex,greyDitherAmnt,greyDitherSdv)*(c1.rgb/c0Max));

float3 XYZ=LinRGB2XYZ(c1.rgb,mode);

c1.rgb =(drk>0)?lerp(c1.rgb,c0OG_lin,1-pow(XYZ.y,drk)):c1.rgb;

c1.rgb=linRGB2rgb(c1.rgb,mode);

return c1;

}