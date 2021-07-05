//Remix of  CeeJay.dk's Splitscreen.fx

#include "ReShadeUI.fxh"

uniform float  split < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Flip unchecked: [Left: Before, Right:After]\n  Flip checked: [Left:After, Right:Before]";
> = 0.5;

uniform bool flip <> = false;

#include "ReShade.fxh"

texture Before { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler Before_sampler { Texture = Before;};

float4 beforePass(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    return tex2D(ReShade::BackBuffer, texcoord);
}

float4 afterPass(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 c0; 

    [branch]if(flip==1){
	        c0=(texcoord.x>split)?tex2D(Before_sampler, texcoord):tex2D(ReShade::BackBuffer, texcoord);
	}else{
	        c0=(texcoord.x<split)?tex2D(Before_sampler, texcoord):tex2D(ReShade::BackBuffer, texcoord);
	}

    return c0;
}

technique Before_shader
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = beforePass;
        RenderTarget = Before;
    }
}
technique After_shader
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = afterPass;
    }
}