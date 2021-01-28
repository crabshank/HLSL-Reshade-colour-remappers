sampler s0 : register(s0);
float4 p0 :  register(c0);
float4 p1 :  register(c1);

#define width   (p0[0])
#define height  (p0[1])
#define counter (p0[2])
#define clock   (p0[3])
#define one_over_width  (p1[0])
#define one_over_height (p1[1])

#define debugColor 1 //0-1 ONLY

#define split 0
#define flip_split 0
#define split_position 0.5

float4 main(float2 tex : TEXCOORD0) : COLOR {

float Split=split;
float Split_position=split_position;
float Flip_split=flip_split;

float4 c0 = tex2D(s0, tex);
float4 c1 = c0;
	
c1.r=(c0.r==max(max(c0.r,c0.g),c0.b))?c1.r+debugColor:c1.r;

c1.g=(c0.g==max(max(c0.r,c0.g),c0.b))?c1.g+debugColor:c1.g;

c1.b=(c0.b==max(max(c0.r,c0.g),c0.b))?c1.b+debugColor:c1.b;

float4 c2=(tex.x>=Split_position*Split)?c1:c0;
float4 c3=(tex.x<=Split_position*Split)?c1:c0;

float4 c4=(Flip_split*Split==1)?c3:c2;

float divLine = abs(tex.x - Split_position) < one_over_width;
c4 =(Split==0)?c4: c4*(1.0 - divLine); //invert divline

return c4;

}
