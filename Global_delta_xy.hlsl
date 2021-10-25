sampler s0 : register(s0);
float4 p0 :  register(c0);
float4 p1 :  register(c1);

#define width   (p0[0])
#define height  (p0[1])
#define counter (p0[2])
#define clock   (p0[3])
#define one_over_width  (p1[0])
#define one_over_height (p1[1])

#define satDeltaAmnt 0 //-1 to <1 - colour include settings have no effect on this setting
#define redDeltaAmnt 0
#define greenDeltaAmnt 0
#define blueDeltaAmnt 0
#define rgbDeltaAmnt 0 //avoid_grey and colour include settings have no effect on this setting
#define Y_DeltaAmnt 0 //avoid_grey and colour include settings have no effect on this setting

#define MODE 3 // 0 - sRGB | 1 - Rec 601 NTSC | 2 - Rec. 601 PAL | 3 - Rec. 709 | 4 - Rec.2020 | 5 - DCI-P3 | 6 - Display P3 | 7 - Orginal NTSC (47 CFR ยง 73.682 - TV transmission standards) | 8 - Rec. 601 D93 | 9 - Rec. 709 D93 | 10 - DCI-P3 (D60/ACES)

#define Linear 0 // 0-1 Take linear RGB as input and output linear RGB

#define avoid_grey 1

#define avoid_light 0

//Apply redDeltaAmnt/greenDeltaAmnt/blueDeltaAmnt to these colours
#define Red 1
#define Orange__Brown 1
#define Yellow 1
#define Chartreuse_Lime 1
#define Green 1
#define Spring_green 1
#define Cyan 1
#define Azure__Sky_blue 1
#define Blue 1
#define Violet__Purple 1
#define Magenta__Pink 1
#define Reddish_pink 1

#define split 0
#define flip_split 0
#define split_position  0.5


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

float3 XYZ2rgb(float3 XYZ, int mode){

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

float3 XYZ2LinRGB(float3 XYZ, int mode){

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

float3 xyY2XYZ(float3 xyY){
       return float3((1.0/xyY.y)*xyY.x*xyY.z, xyY.z,(1.0/xyY.y)*(1-xyY.x-xyY.y)*(xyY.z));
}

float3 XYZ2xyY(float3 XYZ){
	float tot=XYZ.x+XYZ.y+XYZ.z;
	return float3(XYZ.x/tot,XYZ.y/tot,XYZ.y);
}
//Source: https://stackoverflow.com/a/45263428; http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.htm; https://en.wikipedia.org/wiki/Rec._2020#Transfer_characteristics

float delta(float color, float dlt){
[flatten]if(dlt==1){
color=1;
}else if(dlt==-1){
color=0;
}else{
dlt=-0.5*dlt+0.5;
float2 midp=float2(lerp(0,1,dlt),lerp(1,0,dlt));
float relx=color/midp.x;
float relxInv=(1-color)/(1-midp.x);

float newyLow=lerp(0,midp.y,relx);
float newyHi=lerp(1,midp.y,relxInv);

color=(color<=midp.x)?newyLow:newyHi;
}
return color;
}

float4 change(float4 c0, float3 h_sat_val, int Mode, int lin){
	
int red=Red;
int orange__Brown=Orange__Brown;
int yellow=Yellow;
int chartreuse_Lime=Chartreuse_Lime;
int green=Green;
int spring_green=Spring_green;
int cyan=Cyan;
int azure__Sky_blue=Azure__Sky_blue;
int blue=Blue;
int violet__Purple=Violet__Purple;
int magenta__Pink=Magenta__Pink;
int reddish_pink=Reddish_pink;
	
float3 c0Lin=c0.rgb;
	
[branch]if (lin!=1){
c0Lin=rgb2LinRGB(c0.rgb, Mode);
}

float3 c0_og_Lin=c0Lin;

[branch]if(satDeltaAmnt!=0){
float3 dltHSV=rgb2hsv(c0_og_Lin);

float nwSat=delta(dltHSV.y,satDeltaAmnt);
float greyMtrc=lerp(min(dltHSV.y,dltHSV.y*dltHSV.z),dltHSV.y,dltHSV.z);
dltHSV.y=(avoid_grey==1)?lerp(dltHSV.y,nwSat,greyMtrc):nwSat;

c0Lin=hsv2rgb(dltHSV);
}

[branch]if(rgbDeltaAmnt!=0){
c0Lin=float3(delta(c0Lin.r,rgbDeltaAmnt),delta(c0Lin.g,rgbDeltaAmnt),delta(c0Lin.b,rgbDeltaAmnt));
}

[branch]if((redDeltaAmnt!=0)||(greenDeltaAmnt!=0)||(blueDeltaAmnt!=0)){

int hue=floor(h_sat_val.x*3600);
int grey=(((c0.r==c0.g)&&(c0.g==c0.b))||(h_sat_val.y==0))?1:0;

int act=0;

if(((hue>=3525)||(((hue>=0) && (hue<75))&&(grey==0)))&&(red==1)){
act=1;
}else if(((hue>=75) && (hue<375))&&(orange__Brown==1)){
act=1;
}else if(((hue>=375) && (hue<675))&&(yellow==1)){
act=1;
}else if(((hue>=675) && (hue<975))&&(chartreuse_Lime==1)){
act=1;
}else if(((hue>=975) && (hue<1275))&&(green==1)){
act=1;
}else if(((hue>=1275) && (hue<1575))&&(spring_green==1)){
act=1;
}else if(((hue>=1575) && (hue<1875))&&(cyan==1)){
act=1;
}else if(((hue>=1875) && (hue<2175))&&(azure__Sky_blue==1)){
act=1;
}else if(((hue>=2175) && (hue<2475))&&(blue==1)){
act=1;
}else if(((hue>=2475) && (hue<3075))&&(violet__Purple==1)){
act=1;
}else if(((hue>=3075) && (hue<3375))&&(magenta__Pink==1)){
act=1;
}else if(((hue>=3375) && (hue<3525))&&(reddish_pink==1)){
act=1;
}

if (act==1){

c0Lin.r=(redDeltaAmnt==0)?c0Lin.r:delta(c0Lin.r,redDeltaAmnt);

c0Lin.g=(greenDeltaAmnt==0)?c0Lin.g:delta(c0Lin.g,greenDeltaAmnt);

c0Lin.b=(blueDeltaAmnt==0)?c0Lin.b:delta(c0Lin.b,blueDeltaAmnt);

int Avoid_grey=avoid_grey;

float greyMtrc=lerp(min(h_sat_val.y,h_sat_val.y*h_sat_val.z),h_sat_val.y,h_sat_val.z);
c0Lin.rgb=(avoid_grey==1)?lerp(c0_og_Lin.rgb, c0Lin.rgb,greyMtrc):c0Lin.rgb;

}

}

float3 og_XYZ=LinRGB2XYZ(c0_og_Lin,Mode);

int Avoid_light=avoid_light;

c0Lin.rgb=(Avoid_light==1)?lerp(c0Lin.rgb,c0_og_Lin.rgb,og_XYZ.y):c0Lin.rgb;

float nw_Y=(Y_DeltaAmnt==0)?og_XYZ.y:delta(og_XYZ.y,Y_DeltaAmnt);

float3 nw_xyY= XYZ2xyY(LinRGB2XYZ(c0Lin.rgb,Mode));

[branch]if (lin==1){
c0.rgb=XYZ2LinRGB(xyY2XYZ(float3(nw_xyY.xy,nw_Y)),Mode);
}else{
c0.rgb=XYZ2rgb(xyY2XYZ(float3(nw_xyY.xy,nw_Y)),Mode);
}

return c0;

}

float4 main(float2 tex : TEXCOORD0) : COLOR {

float4 c0=tex2D(s0, tex);
float3 c0_hsv=rgb2hsv(c0.rgb);

float Split=split;
float Split_position=split_position;
float Flip_split=flip_split;

int Mode=MODE;
int linr=Linear;

float4 c1=change(c0,c0_hsv,Mode,linr);

float4 c2=(tex.x>=Split_position*Split)?c1:c0;
float4 c3=(tex.x<=Split_position*Split)?c1:c0;

float4 c4=(Flip_split*Split==1)?c3:c2;

float divLine = abs(tex.x - Split_position) < one_over_width;
c4 =(Split==0)?c4: c4*(1.0 - divLine); //invert divline

return c4;
}
