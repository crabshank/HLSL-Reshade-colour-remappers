#include "ReShadeUI.fxh"

uniform int mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0Orignal NTSC D65\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform float3 Custom_RGB < __UNIFORM_COLOR_FLOAT3
	ui_tooltip = "N.B. output will be D65 (white point for most colour spaces)";
> = float3(1, 1, 1);

uniform bool Two_dimensional_input <> = false;

uniform int Two_dimensional_input_type <__UNIFORM_COMBO_INT1
    ui_items = "Crosshairs on\0Crosshairs off\0Direct point-based\0";
	> = 0;	

uniform float Two_dimensional_input_Range < __UNIFORM_SLIDER_FLOAT1
	ui_min = 2.0; ui_max = 0.0;
> = 2.0;

uniform int Debug <__UNIFORM_COMBO_INT1
    ui_items = "Disabled\0Blacken sat <= Debug_thresh\0Saturation change map\0min(chroma, saturation)\0sat <= Debug_thresh to grey\0";
    ui_tooltip = "Saturation change map: Sat unchanged => Green; Sat decreased => Cyan to Blue; Sat increased => Magenta to Orange";
	> = 0;

uniform float Debug_thresh < __UNIFORM_DRAG_FLOAT1
	ui_min = 0; ui_max =1;
> = 0.015;

uniform int Two_dimensional_output_text <__UNIFORM_COMBO_INT1
    ui_items = "RGB + Patch + xy\0RGB + patch\0";
    ui_tooltip = "Print RGB (0-255) to the screen in 2D input mode or RGB with a patch of that colour at the top";
> = 0;

uniform int Decimals < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max =4;
> = 3;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"
#include "DrawText_mod.fxh"

uniform bool buttondown < source = "mousebutton"; keycode = 0; mode = ""; >;

uniform float2 mousepoint < source = "mousepoint"; >;

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

float4 WhitePoint_RGBPass2D(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float4 c1=c0;
float4 c0Lin;
int linr=(Linear==true)?1:0;

[flatten]if(linr==1){
	c0Lin=c0;
}else{
	c0Lin.rgb=rgb2LinRGB(c0.rgb,mode);
}

float4 p0=float4(1,1,1,1);
float4 p0_rnd=float4(255,255,255,255);
float2 Customxy=float2(0.312727,0.329023);

float3 p0_wp=Custom_RGB;

float3 WPgf;
float3 WPgt;

[branch]if(linr==0){
	WPgf= rgb2XYZ(p0_wp.rgb,mode);
	WPgt= rgb2XYZ_grey(p0_wp.rgb,mode);
}else{
	WPgf= LinRGB2XYZ(p0_wp.rgb,mode);
	WPgt= LinRGB2XYZ_grey(p0_wp.rgb,mode);
}

Customxy.xy=XYZ2xyY(WPconv2Grey(WPgf,WPgt)).xy;

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

		[branch]if(linr==0){
			WPgf= rgb2XYZ(p0.rgb,mode);
			WPgt= rgb2XYZ_grey(p0.rgb,mode);
		}else{
			WPgf= LinRGB2XYZ(p0.rgb,mode);
			WPgt= LinRGB2XYZ_grey(p0.rgb,mode);
		}

			[flatten]if(buttondown==0){
				Customxy.xy=XYZ2xyY(WPconv2Grey(WPgf,WPgt)).xy;
			}else{
				Customxy.xy=Customxy;
				p0=Custom_RGB;
				p0_rnd=float3(round(p0.r*255),round(p0.g*255),round(p0.b*255));
			}
			
	}else{
		float2 tmp_xy;
			tmp_xy.x= (buttondown==0)?x_Range*(mousepoint.x*BUFFER_RCP_WIDTH-0.5)+Customxy.x:Customxy.x;
			tmp_xy.y= (buttondown==0)?y_Range*(mousepoint.y*BUFFER_RCP_HEIGHT-0.5)+Customxy.y:Customxy.y;

		float3 xy_XYZ=xy2XYZ(tmp_xy);
		
		[branch]if(linr==0){
			p0=saturate(XYZ2rgb(xy_XYZ,mode));
		}else{
			p0=saturate(XYZ2LinRGB(xy_XYZ,mode));
		}
		
		p0_rnd=float3(round(p0.r*255),round(p0.g*255),round(p0.b*255));

		[branch]if(linr==0){
			WPgf= rgb2XYZ(p0.rgb,mode);
			WPgt= rgb2XYZ_grey(p0.rgb,mode);
		}else{
			WPgf= LinRGB2XYZ(p0.rgb,mode);
			WPgt= LinRGB2XYZ_grey(p0.rgb,mode);
		}

			[flatten]if(buttondown==0){
				Customxy.xy=XYZ2xyY(WPconv2Grey(WPgf,WPgt)).xy;
			}else{
				Customxy.xy=Customxy;
				p0=Custom_RGB;
				p0_rnd=float3(round(p0.r*255),round(p0.g*255),round(p0.b*255));
			}
			
		}
	}

float4 c1_lin=whitePoint(c0Lin,Customxy,1); 

	[flatten]if(linr==0){
		c1.rgb=LinRGB2rgb(c1_lin.rgb,mode);
	}else{
		c1.rgb=c1_lin.rgb;
	}

[branch]if(Debug==1 || Debug==3 || Debug==4){
float max_rgb=max(max(c1.r,c1.g),c1.b);
float min_rgb=min(min(c1.r,c1.g),c1.b);
float chr=max_rgb-min_rgb;
float sat=(max_rgb==0)?0:chr/max_rgb;

[flatten]if(Debug==3){
c1.rgb=(min(chr,sat)<=Debug_thresh)?0.5:c1.rgb;
}else{
c1.rgb=(sat<=Debug_thresh)?((Debug==4)?0.5:0):c1.rgb;
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

[flatten]if(Two_dimensional_input_type==0){
	c1.rgb=c2.rgb;
}else if(Two_dimensional_input_type==1){
		c1.rgb=c3.rgb;
}

float4 res =float4(c1.rgb,0);

float textSize=25;
int decR=Decimals;
int decG=Decimals;
int decB=Decimals;

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


[branch]if(Two_dimensional_output_text==0){ 
	
DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(13, 0), textSize, 1), int2(8, 0), textSize, 1) , 
textSize, 1, texcoord,  Decimals, Customxy.x, res,1);

DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(0.5*BUFFER_WIDTH,0), int2(22, 0), textSize, 1), int2(8, 0), textSize, 1) , 
textSize, 1, texcoord,  Decimals,  Customxy.y, res,1);

}

c1.rgb=res.rgb;
}

p0.rgb=float3(p0_rnd.r*rcptwoFiveFive,p0_rnd.g*rcptwoFiveFive,p0_rnd.b*rcptwoFiveFive);
c1.rgb=(Two_dimensional_input==true && ((texcoord.x>=0.556 && texcoord.x<=0.616) && (texcoord.y<=0.023) ))?p0.rgb:c1.rgb;

return c1;

}

technique White_Point_RGB_2D
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = WhitePoint_RGBPass2D;
	}
}
