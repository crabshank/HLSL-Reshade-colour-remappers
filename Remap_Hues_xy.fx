#include "ReShadeUI.fxh"

uniform int Mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"

float4 RemapHuesxyPass(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float4 colorOrig = tex2D(ReShade::BackBuffer, texcoord);
	float3 colorHSV=rgb2hsv(colorOrig.rgb);
float3 colorOG_xyY;

[branch]if(Linear==false){
	colorOG_xyY=rgb2xyY(colorOrig.rgb,Mode);
}else{
	colorOG_xyY=LinRGB2xyY(colorOrig.rgb,Mode);
}

	float4 color=colorOrig;

	int i=0; 
	int k=0;
	int exact=0;

//////////////////////////////////////////////
//ADJUST IN THIS SECTION!					//
//////////////////////////////////////////////

	float rotate_hues =0;  //-360 to 360

		#define hue_points 3
		float2 h[ hue_points] =
	{
		float2(0, 0),
		float2(180,180),
		float2(360, 360)
	};
//////////////////////////////////////////////	


#if rotate_hues!=0
rotate_hues/=360; float rt=colorHSV.x+rotate_hues; float rt1=(rt<=1)?rt:rt-1; colorHSV.x=(rt<0)?1+rt:rt1; color=hsv2rgb(colorHSV);
#endif

float2 h_x_b=float2(0,1);float2 h_y_b=float2(0,1);i=0;exact=0;for(i=0;i<hue_points;i++){[branch]if(h[i].x/360==colorHSV.x) {colorHSV.x=h[i].y/360;exact=1;i=hue_points-1;}else{if(h[i].x/360<colorHSV.x&&h[i].x/360>=h_x_b.x){h_x_b.x=h[i].x/360;h_y_b.x=h[i].y/360;} if(h[i].x/360<=h_x_b.y&&colorHSV.x<h[i].x/360){h_x_b.y=h[i].x/360;h_y_b.y=h[i].y/360;}}} if(exact==0){colorHSV.x=h_y_b.x+(colorHSV.x-h_x_b.x)*((h_y_b.y-h_y_b.x)/(h_x_b.y-h_x_b.x));};color= hsv2rgb(colorHSV);i=0;exact=0;

float3 color_xyY;

[branch]if(Linear==false){
	color_xyY=XYZ2xyY(rgb2XYZ(color.rgb,Mode));
}else{
	color_xyY=XYZ2xyY(LinRGB2XYZ(color.rgb,Mode));
}

[branch]if(Linear==false){
	color.rgb=xyY2rgb(float3(color_xyY.xy,colorOG_xyY.z),Mode);
}else{
	color.rgb=xyY2LinRGB(float3(color_xyY.xy,colorOG_xyY.z),Mode);
}

return color;

}

technique RemapHues_xy
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = RemapHuesxyPass;
	}
}
