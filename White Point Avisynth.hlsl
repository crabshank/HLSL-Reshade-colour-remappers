sampler s0 : register(s0); 

float4 p0 : register(c0); 
float4 p1 : register(c1);
float2 p2 : register(c2);
float3 p3 : register(c3);
float4 p4 : register(c4);
float4 p5 : register(c5);


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

float3 rgb2LinRGB(float3 rgb, int mode)
{
	float3 rgbLin=rgb;

	[branch]if((mode==0)||(mode==6)){ //sRGB transfer
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

float3 LinRGB2rgb(float3 rgb_i, int mode)
{
	float3 RGB;

	[branch]if((mode==0)||(mode==6)){ //sRGB transfer
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

float3 WPconv_func(float3 XYZ, float3 frm, float3 to)
{
	float3x3 Bradford=float3x3(0.8951,0.2664,-0.1614,
	-0.7502,1.7135,0.0367,
	0.0389,-0.0685,1.0296);

	float3x3 BradfordInv=float3x3(0.9869929,-0.1470543,0.1599627,
	0.4323053,0.5183603,0.0492912,
	-0.0085287,0.0400428,0.9684867);

	float3 BradFrom= mul(Bradford,frm);
	float3 BradTo= mul(Bradford,to);

	float3x3 CR=float3x3(BradTo.x/BradFrom.x,0,0,
	0,BradTo.y/BradFrom.y,0,
	0,0,BradTo.z/BradFrom.z);

	float3x3 convBrad= mul(mul(BradfordInv,CR),Bradford);

	float3 outp=mul(convBrad,XYZ);
	return outp;
}

float3 WPconv(float3 XYZ,float3 frm, float3 to)
{
	return WPconv_func(XYZ, frm, to);
}

float3 WPconv2Grey(float3 frm,float3 to)
{
	return WPconv_func(float3(0.95047,1,1.08883), frm, to); //D65
}

float3 LinRGB2XYZ(float3 rgbLin,int mode)
{
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

float LinRGB2Y(float3 rgbLin,int mode)
{
	float3 v2;
	
	[branch]if (mode==1){ //Rec 601 NTSC
		v2.x=0.2124132;
		v2.y=0.7010437;
		v2.z=0.0865432;
	}else if (mode==2){ //Rec 601 PAL
		v2.x=0.2220379;
		v2.y=0.7066384;
		v2.z=0.0713236;
	}else if(mode==5){ //DCI-P3
		v2.x=0.209491677912731;
		v2.y=0.721595254161044;
		v2.z=0.068913067926226;
	}else if(mode==6){
		v2.x=0.2290036;
		v2.y=0.691726725;
		v2.z=0.079269675;
	}else if (mode==4){ //Rec 2020
		v2.x=0.26272171736164;
		v2.y=0.677989275502262;
		v2.z=0.059289007136098;
	}else if (mode==7){ //Original NTSC
		v2.x=0.2989666;
		v2.y=0.5864212;
		v2.z=0.1146122;
	}else if (mode==8){ //Rec 601 D93
		v2.x=0.1767506;
		v2.y=0.7072321;
		v2.z=0.1160173;
	}else if (mode==9){ //Rec 709 D93
		v2.x=0.1799632;
		v2.y=0.7231169;
		v2.z=0.0969199;
	}else if (mode==10){ //DCI-P3 D60/ACES
		v2.x=0.23762331020788;
		v2.y=0.689170669198985;
		v2.z=0.073206020593136;
	}else{ //sRGB - Rec 709
		v2.x=0.2126729;
		v2.y=0.7151522;
		v2.z=0.072175;
	}

	return dot(v2, rgbLin);
}

float3 XYZ2LinRGB(float3 XYZ, int mode)
{
	float3 v1=float3(0,0,0);
	float3 v2=float3(0,0,0);
	float3 v3=float3(0,0,0);

	[branch]if (mode==1){ //Rec 601 NTSC
		v1.x=3.505396;
		v1.y=-1.7394894;
		v1.z=-0.543964;
		v2.x=-1.0690722;
		v2.y=1.9778245;
		v2.z=0.0351722;
		v3.x=0.05632;
		v3.y=-0.1970226;
		v3.z=1.0502026;
	}else if (mode==2){ //Rec 601 PAL
		v1.x=3.0628971;
		v1.y=-1.3931791;
		v1.z=-0.4757517;
		v2.x=-0.969266;
		v2.y=1.8760108;
		v2.z=0.041556;
		v3.x=0.0678775;
		v3.y=-0.2288548;
		v3.z=1.069349;
	}else if(mode==5){ //DCI-P3
		v1.x=2.72539403049173;
		v1.y=-1.01800300622718;
		v1.z=-0.440163195190036;
		v2.x=-0.795168025808764;
		v2.y=1.68973205484362;
		v2.z=0.022647190608478;
		v3.x=0.0412418913957;
		v3.y=-0.087639019215862;
		v3.z=1.10092937864632;
	}else if(mode==6){
		v1.x=2.49318075532897;
		v1.y=-0.93126552549714;
		v1.z=-0.402659723758882;
		v2.x=-0.829503115821079;
		v2.y=1.76269412111979;
		v2.z=0.02362508874174;
		v3.x=0.035853625780072;
		v3.y=-0.076188954782652;
		v3.z=0.957092621518022;
	}else if (mode==4){ //Rec 2020
		v1.x=1.71651066976197;
		v1.y=-0.355641669986716;
		v1.z=-0.253345541821907;
		v2.x=-0.666693001182624;
		v2.y=1.61650220834691;
		v2.z=0.015768750389995;
		v3.x=0.017643638767459;
		v3.y=-0.042779781669045;
		v3.z=0.942305072720018;
	}else if (mode==7){ //Original NTSC
		v1.x=1.9096754;
		v1.y=-0.5323648;
		v1.z=-0.2881607;
		v2.x=-0.9849649;
		v2.y=1.9997772;
		v2.z=-0.0283168;
		v3.x=0.0582407;
		v3.y=-0.1182463;
		v3.z=0.896554;
	}else if (mode==8){ //Rec 601 D93
		v1.x=4.2126707;
		v1.y=-2.0904617;
		v1.z=-0.6537183;
		v2.x=-1.0597177;
		v2.y=1.9605182;
		v2.z=0.0348645;
		v3.x=0.0420119;
		v3.y=-0.1469691;
		v3.z=0.7833991;
	}else if (mode==9){ //Rec 709 D93
		v1.x=3.8294307;
		v1.y=-1.8165248;
		v1.z=-0.5891432;
		v2.x=-0.9585901;
		v2.y=1.8553477;
		v2.z=0.0410983;
		v3.x=0.0414369;
		v3.y=-0.1519354;
		v3.z=0.7873016;
	}else if (mode==10){ //DCI-P3 D60/ACES
		v1.x=2.40274141422225;
		v1.y=-0.897484163940685;
		v1.z=-0.388053369996071;
		v2.x=-0.832579648740884;
		v2.y=1.76923175357438;
		v2.z=0.023712711514772;
		v3.x=0.038823381466857;
		v3.y=-0.082499685617071;
		v3.z=1.03636859971248;
	}else{ //sRGB - Rec 709
		v1.x=3.2404542;
		v1.y=-1.5371385;
		v1.z=-0.4985314;
		v2.x=-0.969266;
		v2.y=1.8760108;
		v2.z=0.041556;
		v3.x=0.0556434;
		v3.y=-0.2040259;
		v3.z=1.0572252;
	}		
		
	return float3(dot(v1, XYZ),dot(v2, XYZ),dot(v3, XYZ));
	
}

float3 LinRGB2XYZ_grey(float3 rgb,int mode)
{
	float avg=(rgb.r+rgb.g+rgb.b)/3.0;
	float3 rgb_avg=float3(avg,avg,avg);
	return LinRGB2XYZ(rgb_avg, mode);
	
}

float3 XYZ2xyY(float3 XYZ)
{
	float tot=XYZ.x+XYZ.y+XYZ.z;
	//Avoid putting float3(0,0,0) as XYZ!
	
	return float3(XYZ.x/tot,XYZ.y/tot,XYZ.y);
}

float3 xyY2XYZ(float3 xyY)
{
       return float3((1.0/xyY.y)*xyY.x*xyY.z, xyY.z,(1.0/xyY.y)*(1-xyY.x-xyY.y)*(xyY.z));
}

float3 LinRGB2xyY(float3 rgb_lin, int mode)
{
	int rgb_is_blk=(rgb_lin.r==0 && rgb_lin.g==0 && rgb_lin	.b==0)?1:0;
	
	[flatten]if(rgb_is_blk==1){
		rgb_lin.rgb=1;
	}

	float3 XYZ=LinRGB2XYZ(rgb_lin, mode);
	float3 xyY=XYZ2xyY(XYZ);
	xyY.z=(rgb_is_blk==1)?0:xyY.z;
	return xyY;
}

float3 rgb2XYZ(float3 rgb, int mode)
{
	float3 rgb_lin=rgb2LinRGB(rgb, mode);
	return LinRGB2XYZ(rgb_lin,mode);
}

float3 rgb2xyY(float3 rgb, int mode)
{
	float3 rgb_lin=rgb2LinRGB(rgb,mode);
	return LinRGB2xyY(rgb_lin, mode);
}

float3 xyY2LinRGB(float3 xyY, int mode)
{
	float3 XYZ=xyY2XYZ(xyY);
	return XYZ2LinRGB(XYZ, mode);
}

float3 xyY2rgb(float3 xyY, int mode)
{
	float3 lin_rgb=xyY2LinRGB(xyY, mode);
	return LinRGB2rgb(lin_rgb, mode);
}

float3 XYZ2rgb(float3 XYZ, int mode)
{
	float3 rgb_lin=XYZ2LinRGB(XYZ, mode);
	return LinRGB2rgb(rgb_lin, mode);
}

float3 rgb2XYZ_grey(float3 rgb, int mode)
{
	float3 lin_rgb=rgb2LinRGB(rgb, mode);
	return LinRGB2XYZ_grey(lin_rgb, mode);
}

float rgb2Y(float3 rgb, int mode)
{
	float3 lin_rgb=rgb2LinRGB(rgb, mode);
	return LinRGB2Y(lin_rgb, mode);
}

float3 xy2XYZ(float2 xyCoord)
{
	return float3((1/xyCoord.y)*xyCoord.x,1,(1/xyCoord.y)*(1-xyCoord.x-xyCoord.y));
}

//Source: https://stackoverflow.com/a/45263428; http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.htm; https://en.wikipedia.org/wiki/Rec._2020#Transfer_characteristics

float3 WPChangeRGB(float3 color, float3 from, float3 to, int mode, int lin)
{		
	[branch]if(lin==0){
		float3 XYZed=rgb2XYZ(color.rgb,mode);
		return XYZ2rgb(WPconv(XYZed,from,to),mode);
	}else{
		float3 XYZed=LinRGB2XYZ(color.rgb,mode);
		return XYZ2LinRGB(WPconv(XYZed,from,to),mode);
	}
}

float4 whitePoint(float4 color){
float4 c0=color;
float3 D65XYZ=float3(0.95047,1,1.08883);
float2 Customxy;

int mde=round(p4.y);

int dbg=round(p4.z);

int bdt=round(p4.x);

int dst=round(p5.z);

int lnr=round(p5.w);

[branch]if (bdt==1){

float3 WPgf;
float3 WPgt;

[branch]if(lnr==0){
	WPgf= rgb2XYZ(float3(p3.xyz*rcptwoFiveFive),mde);
	WPgt= rgb2XYZ_grey(float3(p3.xyz*rcptwoFiveFive),mde);
}else{
	WPgf= LinRGB2XYZ(float3(p3.xyz*rcptwoFiveFive),mde);
	WPgt= LinRGB2XYZ_grey(float3(p3.xyz*rcptwoFiveFive),mde);
}

	Customxy.xy=XYZ2xyY(WPconv2Grey(WPgf,WPgt)).xy;
	
}else{				
	Customxy=float2(p2.x, p2.y);
} 

float3 CustomXYZ=xy2XYZ(Customxy);

float3 from = D65XYZ; 					
float3 to = CustomXYZ;		

[branch]if (dst==1){
	float3 XYZed02;
[branch]if(lnr==0){
	XYZed02= rgb2XYZ(color.rgb,mde);
}else{
	XYZed02= LinRGB2XYZ(color.rgb,mde);
}

[branch]if(lnr==0){
	color.rgb=XYZ2rgb(WPconv(WPconv(XYZed02,from,to),to,xy2XYZ(float2(p5.xy))),mde);
}else{
		color.rgb=XYZ2LinRGB(WPconv(WPconv(XYZed02,from,to),to,xy2XYZ(float2(p5.xy))),mde);
}

}else{
color.rgb= WPChangeRGB(color.rgb, from, to,mde,lnr);
}


//float OG_max=max(c0.r,max(c0.g,c0.b));
//float OG_min=min(c0.r,min(c0.g,c0.b));
//float OG_sat=(OG_max==0)?0:(OG_max-OG_min)/OG_max;

[branch]if(dbg==1){
float NW_max=max(color.r,max(color.g,color.b));
float NW_min=min(color.r,min(color.g,color.b));
float NW_sat=(NW_max==0)?0:(NW_max-NW_min)/NW_max;

color.rgb=(NW_sat<=p4.w)?float3(0,0,0):color.rgb;
}else if(dbg==2){
float max_rgb=max(max(color.r,color.g),color.b);
float min_rgb=min(min(color.r,color.g),color.b);
float sat=(max_rgb==0)?0:(max_rgb-min_rgb)/max_rgb;

float max_rgb_og=max(max(c0.r,c0.g),c0.b);
float min_rgb_og=min(min(c0.r,c0.g),c0.b);
float sat_og=(max_rgb_og==0)?0:(max_rgb_og-min_rgb_og)/max_rgb_og;

float hue_dbg=120;
    float abs_satDiff=(sat_og==0)?abs(sat_og-sat):abs(sat_og-sat)/sat_og;
    float satDiff1=(sat_og==0)?sat_og-sat:abs(sat_og-sat)/sat_og;
    float satDiff2=(sat_og==1)?sat-sat_og:(sat-sat_og)/(1-sat_og);
	hue_dbg=(sat<sat_og)?lerp(157.5,240,satDiff1):hue_dbg; 
    hue_dbg=(sat>sat_og)?lerp(307.5,367.5,satDiff2):hue_dbg;
    hue_dbg=(hue_dbg==360)?0:hue_dbg;
    hue_dbg=(hue_dbg>360)?hue_dbg-360:hue_dbg;
	
	color.rgb=hsv2rgb(float3(hue_dbg/360.0,1,lerp(0.3*(1-p4.w),1-p4.w,abs_satDiff)));

}

return color;
}

float4 main(float2 tex : TEXCOORD0) : COLOR 
{ 
float4 c0=tex2D( s0, tex );
return whitePoint(c0);
}