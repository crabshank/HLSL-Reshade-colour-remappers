#include "ReShadeUI.fxh"

uniform int mode < __UNIFORM_COMBO_INT1
    ui_items = "sRGB\0Rec 601 NTSC\0Rec. 601 PAL\0Rec. 709\0Rec.2020\0DCI-P3\0Display P3\0Orginal NTSC\0Rec. 601 D93\0Rec. 709 D93\0DCI-P3 (D60/ACES)\0Orignal NTSC D65\0";
> = 0;

uniform bool Linear <
ui_tooltip = "Take linear RGB as input and output linear RGB";
> = false;

uniform float3 XYZ < __UNIFORM_INPUT_FLOAT3
	ui_min = 0.0; ui_step=0.000001; ui_max = 3.0; ui_tooltip = "(0.95047,1,1.08883) is D65";
> =float3(0.95047,1,1.08883); //D65;

uniform bool Two_dimensional_input <> = false;

uniform float Two_dimensional_Y < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_step=0.001; ui_max = 1.0;
> = 1;

uniform float Two_dimensional_Y_Fine < __UNIFORM_DRAG_FLOAT1
	ui_min = 0; ui_step=1; ui_max =99; ui_tooltip = "Set the 4th and 5th decimal points";
> = 0;

uniform int Decimals < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max =5;
> = 3;

#include "ReShade.fxh"
#include "xyY_funcs.fxh"
#include "DrawText_mod.fxh"

uniform bool buttondown < source = "mousebutton"; keycode = 0; mode = ""; >;

uniform float2 mousepoint < source = "mousepoint"; >;

float4 XYZ_finderPass2D(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{

float4 c0=tex2D(ReShade::BackBuffer, texcoord);
float4 c1=c0;
float4 c0Lin;
int linr=(Linear==true)?1:0;
float4 p0=float4(1,1,1,1);
float4 p0_rnd=float4(255,255,255,255);
float textSize=25;
int decR=Decimals;
int decG=Decimals;
int decB=Decimals;
float rd;
float gr;
float bl;
float half_bw=0.5*BUFFER_WIDTH;
float4 res;
float inv_Y_val;
float Two_D_Y=Two_dimensional_Y+(Two_dimensional_Y_Fine*0.00001);

[flatten]if(linr==1){
	c0Lin=c0;
}else{
	c0Lin.rgb=rgb2LinRGB(c0.rgb,mode);
}


float xCoord_Pos;
float yCoord_Pos;

[branch]if(Two_dimensional_input==true){
	
/*	float x_Range=(BUFFER_WIDTH>=BUFFER_HEIGHT)?Two_dimensional_input_Range*(BUFFER_RCP_HEIGHT/BUFFER_RCP_WIDTH):Two_dimensional_input_Range;

	float y_Range=(BUFFER_WIDTH>=BUFFER_HEIGHT)?Two_dimensional_input_Range:Two_dimensional_input_Range*(BUFFER_RCP_WIDTH/BUFFER_RCP_HEIGHT);*/

	xCoord_Pos=mousepoint.x*BUFFER_RCP_WIDTH;
	yCoord_Pos=mousepoint.y*BUFFER_RCP_HEIGHT;
	
	float2 tmp_xy;
float2 tmp_xy2;
	
			tmp_xy.x= mousepoint.x*BUFFER_RCP_WIDTH;
			tmp_xy.y= 1-mousepoint.y*BUFFER_RCP_HEIGHT;
			
		tmp_xy2.x= texcoord.x;
			tmp_xy2.y= 1-texcoord.y;

		float3 xy_XYZ=xyY2XYZ(float3(tmp_xy,Two_D_Y));

		[branch]if(linr==0){
			p0=saturate(XYZ2rgb(xy_XYZ,mode));
		}else{
			p0=saturate(XYZ2LinRGB(xy_XYZ,mode));
		}
		[branch]if(linr==0){
			c1.rgb=xyY2rgb(float3(tmp_xy2.xy,Two_D_Y), mode);
		}else{
			c1.rgb=xyY2LinRGB(float3(tmp_xy2.xy,Two_D_Y), mode);
		}
		
			res =float4(c1.rgb,0);
		inv_Y_val=(xy_XYZ.y<0.5)?1:0;
				    DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(half_bw,0), int2(-20, 2), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  Decimals, xy_XYZ.x, res,inv_Y_val ); 
						
					DrawText_Digit(DrawText_Shift(DrawText_Shift(float2(half_bw,0), int2(-10, 2), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  Decimals, xy_XYZ.y, res, inv_Y_val);			

						DrawText_Digit(DrawText_Shift(DrawText_Shift(float2(half_bw,0), int2(0, 2), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  Decimals, xy_XYZ.z, res,inv_Y_val);
		
}else{ 	
	[branch]if(linr==0){
			p0=saturate(XYZ2rgb(XYZ,mode));
		}else{
			p0=saturate(XYZ2LinRGB(XYZ,mode));
		}
		res =float4(c1.rgb,0);
		inv_Y_val=(XYZ.y<0.5)?1:0;
		       DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(half_bw,0), int2(-20, 2), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  Decimals, XYZ.x, res,inv_Y_val); 
						
					DrawText_Digit(DrawText_Shift(DrawText_Shift(float2(half_bw,0), int2(-10, 2), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  Decimals, XYZ.y, res,inv_Y_val);			

						DrawText_Digit(DrawText_Shift(DrawText_Shift(float2(half_bw,0), int2(0,2), textSize, 1), int2(8, 0), textSize, 1) , 
						textSize, 1, texcoord,  Decimals, XYZ.z, res,inv_Y_val);
						res.rgb =p0.rgb;
}
	
p0_rnd=float3(round(p0.r*255),round(p0.g*255),round(p0.b*255));

	 rd=p0_rnd.r;
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
	
	gr=p0_rnd.g;
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
	
	bl=p0_rnd.b;
	
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


		DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(half_bw,0), int2(-15, 1), textSize, 1), int2(8, 0), textSize, 1) , 
			textSize, 1, texcoord,  -decR, rd, res,inv_Y_val);

			DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(half_bw,0), int2(-10, 1), textSize, 1), int2(8, 0), textSize, 1) , 
			textSize, 1, texcoord,  -decG, gr, res,inv_Y_val);

			DrawText_Digit(   DrawText_Shift(DrawText_Shift(float2(half_bw,0), int2(-5, 1), textSize, 1), int2(8, 0), textSize, 1) , 
			textSize, 1, texcoord,  -decB, bl, res,inv_Y_val);


	c1.rgb=res.rgb;
c1.rgb=(Two_dimensional_input==true && ((texcoord.x>=0.461 && texcoord.x<=0.545) && (texcoord.y<=0.023) ))?p0.rgb:c1.rgb;
return c1;

}

technique XYZ_finder_2D
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = XYZ_finderPass2D;
	}
}
