#include "ReShadeUI.fxh"

uniform int mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform float2 Custom_xy < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_step=0.001; ui_max = 1.0;
	ui_tooltip = "N.B. output will be D65 (white point for most colour spaces)";
> =float2(0.312727,0.329023);

uniform float2 Custom_xy_bb < __UNIFORM_DRAG_FLOAT2
	ui_min = 0.0; ui_step=0.001; ui_max = 1.0;
	ui_tooltip = "N.B. output will be D65 (white point for most colour spaces)";
> =float2(0.312727,0.329023);

uniform int Balance <__UNIFORM_COMBO_INT1
    ui_items = "White point only\0White point + black balance\0Black balance only\0";
	> = 0;

uniform bool Two_dimensional_input <> = false;

uniform int Two_dimensional_input_type <__UNIFORM_COMBO_INT1
    ui_items = "Crosshairs on\0Crosshairs off\0Direct point-based\0";
	> = 0;
	
	uniform int Two_dimensional_input_for <__UNIFORM_COMBO_INT1
    ui_items = "White Point\0Black Balance\0";
	> = 0;

uniform float Two_dimensional_input_Range < __UNIFORM_SLIDER_FLOAT1
	ui_min = 2.0; ui_max = 0.0;
> = 2.0;

uniform int Debug <__UNIFORM_COMBO_INT1
    ui_items = "Disabled\0Blacken sat <= Debug_thresh\0Saturation change map\0min(chroma, saturation)\0";
    ui_tooltip = "Saturation change map: Sat unchanged => Green; Sat decreased => Cyan to Blue; Sat increased => Magenta to Orange";
	> = 0;

uniform float Debug_thresh < __UNIFORM_DRAG_FLOAT1
	ui_min = 0; ui_max =1;
> = 0.015;

uniform int Two_dimensional_output_text <__UNIFORM_COMBO_INT1
    ui_items = "xy\0RGB\0RGB + patch\0";
    ui_tooltip = "Print xy or RGB (0-255) to the screen in 2D input mode or RGB with a patch of that colour at the top (last 2 only work if 'Two_dimensional_input_type'=='Direct point-based')";
> = 0;

uniform int Decimals < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max =4;
> = 3;

#include "ReShade.fxh"
#include "DrawText_mod.fxh"

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

uniform bool buttondown < source = "mousebutton"; keycode = 0; mode = ""; >;

uniform float2 mousepoint < source = "mousepoint"; >;

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


float3 WPconv(float3 XYZ,float3 from, float3 to){

float3x3 Bradford=float3x3(0.8951,0.2664,-0.1614,
-0.7502,1.7135,0.0367,
0.0389,-0.0685,1.0296);

float3x3 BradfordInv=float3x3(0.9869929,-0.1470543,0.1599627,
0.4323053,0.5183603,0.0492912,
-0.0085287,0.0400428,0.9684867);


float3 BradFrom= mul(Bradford,from);
float3 BradTo= mul(Bradford,to);

float3x3 CR=float3x3(BradTo.x/BradFrom.x,0,0,
0,BradTo.y/BradFrom.y,0,
0,0,BradTo.z/BradFrom.z);

float3x3 convBrad= mul(mul(BradfordInv,CR),Bradford);

float3 outp=mul(convBrad,XYZ);
return outp;


}

float3 WPconv2Grey(float3 from, float3 to){

float3x3 Bradford=float3x3(0.8951,0.2664,-0.1614,
-0.7502,1.7135,0.0367,
0.0389,-0.0685,1.0296);

float3x3 BradfordInv=float3x3(0.9869929,-0.1470543,0.1599627,
0.4323053,0.5183603,0.0492912,
-0.0085287,0.0400428,0.9684867);

float3 BradFrom= mul(Bradford,from);
float3 BradTo= mul(Bradford,to);

float3x3 CR=float3x3(BradTo.x/BradFrom.x,0,0,
0,BradTo.y/BradFrom.y,0,
0,0,BradTo.z/BradFrom.z);

float3x3 convBrad= mul(mul(BradfordInv,CR),Bradford);

float3 outp=mul(convBrad,float3(0.95047,1,1.08883));

return outp;

}

float3 XYZ2rgb(float3 XYZ, int mode, int lin){

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

float3 rgb_i=float3(dot(v1, XYZ),dot(v2, XYZ),dot(v3, XYZ));

float3 RGB=rgb_i;

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

float3 rgb2XYZ(float3 rgb,int mode, int lin){

	  float3 rgbLin=rgb;
	  
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

float3 rgb2XYZ_grey(float3 rgb,int mode, int lin){

	  float3 rgbLin=rgb;

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


    float rgbNewTot=rgbLin.x+rgbLin.y+rgbLin.z;
    float rgbNewAvg=rgbNewTot/3;
    float3 rgbNew=rgbNewAvg;

	return float3(dot(v1, rgbNew),dot(v2, rgbNew), dot(v3, rgbNew));

}

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

float3 LinRGB2rgb(float3 rgb_i,int mode){

float3 RGB;

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

//Source: https://stackoverflow.com/a/45263428; http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.htm; https://en.wikipedia.org/wiki/Rec._2020#Transfer_characteristics

float3 WPChangeRGB(float3 color, float3 from, float3 to, int mode, int lin){

float3 XYZed=rgb2XYZ(color.rgb,mode, lin);
return XYZ2rgb(WPconv(XYZed,from,to),mode, lin);

}

float3 xy2XYZ(float2 xyCoord){
return float3((1/xyCoord.y)*xyCoord.x,1,(1/xyCoord.y)*(1-xyCoord.x-xyCoord.y));
}

float3 XYZ2xyY(float3 XYZ){
	float XYZtot=XYZ.x+XYZ.y+XYZ.z;
	
	float x=XYZ.x/XYZtot;
	float y=XYZ.y/XYZtot;
	return float3(x,y,XYZ.y);
}

float4 whitePoint(float4 color, float2 CustomxyIn, int lin){

float4 c0=color;

float2 D65xy=float2(0.312727,0.329023);

float3 D65XYZ=xy2XYZ(D65xy);
float3 CustomXYZ=xy2XYZ(CustomxyIn);

float3 from = D65XYZ; 
float3 to = CustomXYZ;

color.rgb= WPChangeRGB(color.rgb, from, to,mode,lin);

return color;
}

float4 WhitePoint_BlackBalancePass2D(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float4 c1=c0;
float4 c0Lin;
int linr=(Linear==true)?1:0;

[branch]if(linr==1){
	c0Lin=c0;
}else{
	c0Lin.rgb=rgb2LinRGB(c0.rgb,mode);
}

float4 p0=float4(1,1,1,1);
float4 p0_rnd=float4(255,255,255,255);


float2 Customxy=Custom_xy;
float2 Customxy_bb=Custom_xy_bb;

float xCoord_Pos;
float yCoord_Pos;

[branch]if(Two_dimensional_input==true){
	
	float x_Range=(BUFFER_WIDTH>=BUFFER_HEIGHT)?Two_dimensional_input_Range*(BUFFER_RCP_HEIGHT/BUFFER_RCP_WIDTH):Two_dimensional_input_Range;

	float y_Range=(BUFFER_WIDTH>=BUFFER_HEIGHT)?Two_dimensional_input_Range:Two_dimensional_input_Range*(BUFFER_RCP_WIDTH/BUFFER_RCP_HEIGHT);

	xCoord_Pos=(buttondown==1)?0.5:mousepoint.x*BUFFER_RCP_WIDTH;
	yCoord_Pos=(buttondown==1)?0.5:mousepoint.y*BUFFER_RCP_HEIGHT;

	[flatten]if(Two_dimensional_input_type==2){
		p0=tex2D(ReShade::BackBuffer, mousepoint*float2(BUFFER_RCP_WIDTH,BUFFER_RCP_HEIGHT));

		p0_rnd=float3(round(p0.r*255),round(p0.g*255),round(p0.b*255));

		float3 WPgf= rgb2XYZ(p0.rgb,mode,linr);
		float3 WPgt= rgb2XYZ_grey(p0.rgb,mode,linr);

		[flatten]if(Two_dimensional_input_for==0){
		Customxy.xy=(buttondown==0)?XYZ2xyY(WPconv2Grey(WPgf,WPgt)).xy:Customxy;
		}else{
		Customxy_bb.xy=(buttondown==0)?XYZ2xyY(WPconv2Grey(WPgf,WPgt)).xy:Customxy_bb;
		}

	}else{
		[flatten]if(Two_dimensional_input_for==0){
		Customxy.x= (buttondown==0)?x_Range*(mousepoint.x*BUFFER_RCP_WIDTH-0.5)+Customxy.x:Customxy.x;
		Customxy.y= (buttondown==0)?y_Range*(mousepoint.y*BUFFER_RCP_HEIGHT-0.5)+Customxy.y:Customxy.y;
		}else{
		Customxy_bb.x= (buttondown==0)?x_Range*(mousepoint.x*BUFFER_RCP_WIDTH-0.5)+Customxy_bb.x:Customxy_bb.x;
		Customxy_bb.y= (buttondown==0)?y_Range*(mousepoint.y*BUFFER_RCP_HEIGHT-0.5)+Customxy_bb.y:Customxy_bb.y;
		}
	}

}

float4 c1_lin=whitePoint(c0Lin,((Balance==2)?Customxy_bb:Customxy),1); 

[branch]if(Balance==1){ //WP+bb
	float4 c1_bb_lin=whitePoint(c0Lin,Customxy_bb,1);

float mn=min(c1_lin.r,min(c1_lin.g,c1_lin.b));
float mx=max(c1_lin.r,max(c1_lin.g,c1_lin.b));
float chr=mx-mn;
float sat=(mx==0)?0:chr/mx;


float mn_bb=min(c1_bb_lin.r,min(c1_bb_lin.g,c1_bb_lin.b));
float mx_bb=max(c1_bb_lin.r,max(c1_bb_lin.g,c1_bb_lin.b));
float chr_bb=mx_bb-mn_bb;
float sat_bb=(mx_bb==0)?0:chr_bb/mx_bb;
float h=0;
if(chr!=0){
	if ((c1_lin.r >= c1_lin.g) && (c1_lin.r >= c1_lin.b)) {
		h=(c1_lin.g - c1_lin.b) / chr;
	} else if ((c1_lin.g >= c1_lin.r) && (c1_lin.g >= c1_lin.b)) {
	   h = (c1_lin.b - c1_lin.r) / chr + 2.0;
	} else {
		h = (c1_lin.r - c1_lin.g) / chr + 4.0;
	}
	h/=6.0;
	h=(h < 0) ? h + 1 : h;
}


float3 c1_lin_adj_hsv=float3(h, min(sat,sat_bb), mx);

c1_bb_lin=hsv2rgb(c1_lin_adj_hsv);
	
	[branch]if(linr==0){
		c1.rgb=LinRGB2rgb(c1_bb_lin.rgb,mode);
	}else{
		c1.rgb=c1_bb_lin.rgb;
	}
	
}else{
	[branch]if(linr==0){
		c1.rgb=LinRGB2rgb(c1_lin.rgb,mode);
	}else{
		c1.rgb=c1_lin.rgb;
	}
}

[branch]if(Debug==1 || Debug==3){
float max_rgb=max(max(c1.r,c1.g),c1.b);
float min_rgb=min(min(c1.r,c1.g),c1.b);
float chr=max_rgb-min_rgb;
float sat=(max_rgb==0)?0:chr/max_rgb;

[flatten]if(Debug==3){
c1.rgb=(min(chr,sat)<=Debug_thresh)?0.5:c1.rgb;
}else{
c1.rgb=(sat<=Debug_thresh)?0:c1.rgb;
}

}else if(Debug==2){
float max_rgb=max(max(c1.r,c1.g),c1.b);
float min_rgb=min(min(c1.r,c1.g),c1.b);
float sat=(max_rgb==0)?0:(max_rgb-min_rgb)/max_rgb;

float max_rgb_og=max(max(c0.r,c0.g),c0.b);
float min_rgb_og=min(min(c0.r,c0.g),c0.b);
float sat_og=(max_rgb_og==0)?0:(max_rgb_og-min_rgb_og)/max_rgb_og;

float hue_dbg=120;
    float abs_satDiff=(sat_og==0)?abs(sat_og-sat):abs(sat_og-sat)/sat_og;
    float satDiff1=(sat_og==0)?sat_og-sat:abs(sat_og-sat)/sat_og;
     satDiff1=satDiff1*satDiff1;
    float satDiff2=(sat_og==1)?sat-sat_og:(sat-sat_og)/(1-sat_og);
     satDiff2=satDiff2*satDiff2;
	hue_dbg=(sat<sat_og)?lerp(157.5,240,satDiff1):hue_dbg; 
    hue_dbg=(sat>sat_og)?lerp(307.5,367.5,satDiff2):hue_dbg;
    hue_dbg=(hue_dbg==360)?0:hue_dbg;
    hue_dbg=(hue_dbg>360)?hue_dbg-360:hue_dbg;
	
	c1.rgb=hsv2rgb(float3(hue_dbg/360.0,1,lerp(0.3*(1-Debug_thresh),1-Debug_thresh,abs_satDiff)));

}

float4 c2;
float4 c3;

[branch]if(Two_dimensional_input==true){
	
c2.rgb =(abs(texcoord.x-xCoord_Pos)<BUFFER_RCP_WIDTH || abs(texcoord.y-yCoord_Pos)<BUFFER_RCP_HEIGHT)?float3(0.369,0.745,0):c1.rgb;

c3.rgb =(abs(texcoord.x-xCoord_Pos)<3*BUFFER_RCP_WIDTH && abs(texcoord.y-yCoord_Pos)<3*BUFFER_RCP_HEIGHT)?float3(0.498,1,0):c1.rgb;

[branch]if(Two_dimensional_input_type==0){
	c1.rgb=c2.rgb;
}else if(Two_dimensional_input_type==1){
		c1.rgb=c3.rgb;
}

float4 res =float4(c1.rgb,0);

float textSize=25;
int decR=Decimals;
int decG=Decimals;
int decB=Decimals;
if((Two_dimensional_output_text==1 || Two_dimensional_output_text==2) && Two_dimensional_input_type==2){
	float rd=p0_rnd.r;
	[flatten]if(rd>=100){
		rd=rd*0.001;
		decR=3;
	}else if(rd>=10){
		rd=rd*0.01;
		decR=2;
	}else{
		rd=rd*0.1;
		decR=1;
	}	
	
	float gr=p0_rnd.g;
	[flatten]if(gr>=100){
		gr=gr*0.001;
		decG=3;
	}else if(gr>=10){
		gr=gr*0.01;
		decG=2;
	}else{
		gr=gr*0.1;
		decG=1;
	}	
	
	float bl=p0_rnd.b;
	
	[flatten]if(bl>=100){
		bl=bl*0.001;
		decB=3;
	}else if(bl>=10){
		bl=bl*0.01;
		decB=2;
	}else{
		bl=bl*0.1;
		decB=1;
	}


DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(-15, 0), textSize, 1), int2(8, 0), textSize, 1) , 
textSize, 1, texcoord,  -decR, rd, res,1);

DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(-10, 0), textSize, 1), int2(8, 0), textSize, 1) , 
textSize, 1, texcoord,  -decG, gr, res,1);

DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(-5, 0), textSize, 1), int2(8, 0), textSize, 1) , 
textSize, 1, texcoord,  -decB, bl, res,1);

}else{
	
DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(-14, 0), textSize, 1), int2(8, 0), textSize, 1) , 
textSize, 1, texcoord,  Decimals, Customxy.x, res,1);

DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(-5, 0), textSize, 1), int2(8, 0), textSize, 1) , 
textSize, 1, texcoord,  Decimals,  Customxy.y, res,1);

}

c1.rgb=res.rgb;
}

p0.rgb=float3(p0_rnd.r*rcptwoFiveFive,p0_rnd.g*rcptwoFiveFive,p0_rnd.b*rcptwoFiveFive);
c1.rgb=(Two_dimensional_input==true && Two_dimensional_input_type==2 && Two_dimensional_output_text==2 && ((texcoord.x>=0.556 && texcoord.x<=0.616) && (texcoord.y<=0.023) ))?p0.rgb:c1.rgb;

return c1;

}

technique White_Point_Black_Balance_2D
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = WhitePoint_BlackBalancePass2D;
	}
}
