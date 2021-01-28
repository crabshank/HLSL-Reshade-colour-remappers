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
	#define third 1.0/3.0

	float3x3 invThreeByThreeMatrix(float3x3 mtx){

	float el_A=mtx[1][1]*mtx[2][2]-mtx[1][2]*mtx[2][1];
	float el_B=-(mtx[1][0]*mtx[2][2]-mtx[1][2]*mtx[2][0]);
	float el_C=mtx[1][0]*mtx[2][1]-mtx[1][1]*mtx[2][0];
	float el_D=-(mtx[0][1]*mtx[2][2]-mtx[0][2]*mtx[2][1]);
	float el_E=mtx[0][0]*mtx[2][2]-mtx[0][2]*mtx[2][0];
	float el_F=-(mtx[0][0]*mtx[2][1]-mtx[0][1]*mtx[2][0]);
	float el_G=mtx[0][1]*mtx[1][2]-mtx[0][2]*mtx[1][1];
	float el_H=-(mtx[0][0]*mtx[1][2]-mtx[0][2]*mtx[1][0]);
	float el_I=mtx[0][0]*mtx[1][1]-mtx[0][1]*mtx[1][0];

	float det=mtx[0][0]*el_A+mtx[0][1]*el_B+mtx[0][2]*el_C;

	float invDet=1/det;

	float3x3 outp=invDet*float3x3(el_A,el_D,el_G,
	el_B,el_E,el_H,
	el_C,el_F,el_I);

		return outp;
	}

	float3 Primaryconv(float2 red, float2 green, float2 blue, float3 XYZ, int lin, int mode){

	float3 XYZ_r=float3(red.xy,1-red.x-red.y);
	float3 XYZ_g=float3(green.xy,1-green.x-green.y);
	float3 XYZ_b=float3(blue.xy,1-blue.x-blue.y);

	float3x3 XYZ_rgb=float3x3(XYZ_r.x,XYZ_g.x,XYZ_b.x,
	XYZ_r.y,XYZ_g.y,XYZ_b.y,
	XYZ_r.z,XYZ_g.z,XYZ_b.z);

	float3x3 inv_XYZ_rgb=invThreeByThreeMatrix(XYZ_rgb);

	float3 WP=float3(0.95047,1,1.08883); //D65

	[branch]if(mode==5){
	WP=float3(0.8945869,1,0.954416);
	}else if((mode==8)||(mode==9)){
	WP=float3(0.9528778,1,1.4129923);
	}else if(mode==10){
	WP=float3(0.9526461,1,1.0088252);
	}

	float3 s_XYZ=mul(inv_XYZ_rgb,WP);

	float3x3 s_mat=float3x3(s_XYZ.x,0,0,
	0,s_XYZ.y,0,
	0,0,s_XYZ.z);

	float3x3 inv_s_mat=invThreeByThreeMatrix(mul(XYZ_rgb,s_mat));

float3 rgb_i=mul(inv_s_mat,XYZ);

float3 RGB;

[branch]if(lin==0){
if ((mode==0)||(mode==6)){ //sRGB transfer
      RGB=(rgb_i> 0.00313066844250063)?1.055 * pow(rgb_i,rcpTwoFour) - 0.055:12.92 *rgb_i;
}else if ((mode==5)||(mode==10)){ //DCI-P3
      RGB=pow(rgb_i,invTwoSix);
}else if (mode==7){ //Original NTSC - Source: 47 CFR, Section 73.682 - TV transmission standards
      RGB=pow(rgb_i,invTwoTwo);
}else{ //Rec transfer
      RGB=(rgb_i< recBeta)?4.5*rgb_i:recAlpha*pow(rgb_i,0.45)-(recAlpha-1);
}
}

	return RGB;

	}
	//Source: http://www.ryanjuckett.com/programming/rgb-color-space-conversion/

	float3 rgb2XYZ(float3 rgb,int mode, int lin){

	  float3 rgbLin;
	  
[branch]if(lin==0){
if ((mode==0)||(mode==6)){ //sRGB transfer
    rgbLin=(rgb > 0.0404482362771082 )?pow(abs((rgb+0.055)*rcpOFiveFive),2.4):rgb*rcpTwelveNineTwo;
}else if ((mode==5)||(mode==10)){ //DCI-P3
    rgbLin=pow(rgb,2.6);
}else if (mode==7){ //Original NTSC
    rgbLin=pow(rgb,2.2);
}else{ //Rec transfer
    rgbLin=(rgb < recBetaLin )?rcpFourFive*rgb:pow(-1*(rcpRecAlpha*(1-recAlpha-rgb)),rcpTxFourFive);
}
}

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

		
		return float3(dot(v1, rgbLin),dot(v2, rgbLin), dot(v3, rgbLin));


	}

	//Source: https://stackoverflow.com/a/45263428; http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.htm; https://en.wikipedia.org/wiki/Rec._2020#Transfer_characteristics

	float3 XYZ2xyY(float3 XYZ){
		float XYZtot=XYZ.x+XYZ.y+XYZ.z;
		
		float x=XYZ.x/XYZtot;
		float y=XYZ.y/XYZtot;
		return float3(x,y,XYZ.y);
	}

	#define mode 3 // 0 - sRGB | 1 - Rec 601 NTSC | 2 - Rec. 601 PAL | 3 - Rec. 709 | 4 - Rec.2020 | 5 - DCI-P3 | 6 - Display P3 | 7 - Orginal NTSC (47 CFR ยง 73.682 - TV transmission standards) | 8 - Rec. 601 D93 | 9 - Rec. 709 D93 | 10 - DCI-P3 (D60/ACES)

	#define Debug 0
	#define DebugCol 0 // 0, 1, 2; - 0 for Red; 1 for Green; 2 for Blue;
	#define DebugAmplification 0.5
	#define Colour_bars 0
	#define linear 0 // 0-1; Accept linear RGB as input and ouput linear RGB too

	#define Split 0
	#define Flip_split 0
	#define Split_Position 0.5;

	float4 main(float2 tex : TEXCOORD0) : COLOR 
	{ 
	 
	 ////////////SET////////////////////////////////
	 
	float2 to_Red = float2(0.64,0.33);
	float2 to_Green = float2(0.3,0.6);
	float2 to_Blue = float2(0.15,0.06);

	///////////////THIS///////////////////////
	 
	float4 c0=tex2D( s0, tex );

	float Split_position=Split_Position;

	int Mode=round(mode);
	int linr=round(linear);

	float2 Customxy;

	float4 c1=c0;

	c1.rgb=Primaryconv(to_Red,to_Green,to_Blue,rgb2XYZ(c0.rgb,Mode,linr),linr,Mode);

	float3 dbgCol=float3(1,1,1);

	if(Debug==1){

	dbgCol=(tex.x<=third)?float3(1,0,0):dbgCol;
	dbgCol=(tex.x>third && tex.x<=2*third)?float3(0,1,0):dbgCol;
	dbgCol=(tex.x>2*third)?float3(0,0,1):dbgCol;

	float2 OGxy=XYZ2xyY(rgb2XYZ(c0.rgb,Mode,linr)).xy;
	float2 Currxy=XYZ2xyY(rgb2XYZ(c1.rgb,Mode,linr)).xy;

	if(Debug==1){

	if(DebugCol==0){

	if(Colour_bars==0){
	c1.rgb=pow(min(1,sqrt(pow(0.64-Currxy.x,2)+pow(0.33-Currxy.y,2))),DebugAmplification);
	c0.rgb=(Split==1)?pow(min(1,sqrt(pow(0.64-OGxy.x,2)+pow(0.33-OGxy.y,2))),DebugAmplification):c0.rgb;
	}else{
	c1.rgb=Primaryconv(to_Red,to_Green,to_Blue,rgb2XYZ(dbgCol,Mode,1),linr,Mode);
	c0.rgb=c1.rgb;
	}

	}else if(DebugCol==1){

	if(Colour_bars==0){
	c1.rgb=pow(min(1,sqrt(pow(0.3-Currxy.x,2)+pow(0.6-Currxy.y,2))),DebugAmplification);
	c0.rgb=(Split==1)?pow(min(1,sqrt(pow(0.3-OGxy.x,2)+pow(0.6-OGxy.y,2))),DebugAmplification):c0.rgb;
	}else{
	c1.rgb=Primaryconv(to_Red,to_Green,to_Blue,rgb2XYZ(dbgCol,Mode,1),linr,Mode);
	c0.rgb=c1.rgb;
	}

	}else if(DebugCol==2){

	if(Colour_bars==0){
	c1.rgb=pow(min(1,sqrt(pow(0.15-Currxy.x,2)+pow(0.06-Currxy.y,2))),DebugAmplification);
	c0.rgb=(Split==1)?pow(min(1,sqrt(pow(0.15-OGxy.x,2)+pow(0.06-OGxy.y,2))),DebugAmplification):c0.rgb;
	}else{
	c1.rgb=Primaryconv(to_Red,to_Green,to_Blue,rgb2XYZ(dbgCol,Mode,1),linr,Mode);
	c0.rgb=c1.rgb;
	}

	}
	}
	}

	float4 c2=(tex.x>=Split_position*Split)?c1:c0;
	float4 c3=(tex.x<=Split_position*Split)?c1:c0;

	float4 c4=(Flip_split==1 && Split==1)?c3:c2;

	float divLine = abs(tex.x - Split_position) < one_over_width;
	c4 =(Split==0 || (Debug==1 && Colour_bars==1))?c4: c4*(1.0 - divLine); //invert divline

	return c4;

	}