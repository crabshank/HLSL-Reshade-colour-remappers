#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <math.h>
#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))


    void twoD_sort_asc( int r, int c,void* mtx,int d){

      int (*m)[c] = (int (*)[c]) mtx;

      //double *pmtx = &m[0][0];

        int j,a,b,e,i;
        d=(d==1)?1:0;
        e=(d==0)?1:0;

        for (i = 0; i < c; ++i)
        {
            for (j = i + 1; j < c; ++j)
            {
                if (m[0][i] < m[0][j])
                {
                    a = m[d][i];
                    b = m[e][i];
                    m[d][i] = m[d][j];
                    m[e][i] = m[e][j];
                    m[d][j] = a;
                    m[e][j] = b;
                }
            }
        }
    }

HINSTANCE hInst;
HWND hwnd;
POINT p;
BOOL b;
char str_out[MAX_PATH]={0};
char str_out2[MAX_PATH]={0};
char str_out3[MAX_PATH]={0};
char str_out4[MAX_PATH]={0};
char str_out5[MAX_PATH]={0};

int smp = 10;
int smp2 = 0;
int smp3 = 0;
int smp4 = 72;
int smp5 = 287;
int Ro=0;
int Go=0;
int Bo=0;
char* nomin_hue="";
double sat_out=0;
double hue_out=0;
int out_col=0;
HBRUSH hBrush = CreateSolidBrush(RGB(0,0,0));
PAINTSTRUCT ps;

HDC hdc;
COLORREF color;
HGDIOBJ oldObject;

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{

    switch(message)
    {
        case WM_PAINT:
        {
 RECT  xy_txt = {0,smp,0, 0};
 int ctK=0;
 int altK=0;



   if(GetAsyncKeyState(VK_SHIFT) && !(GetAsyncKeyState(VK_CONTROL)) && !(GetAsyncKeyState(VK_MENU))){
if(GetAsyncKeyState(0x41)){
    smp=(smp>=2)?smp-1:smp;
	smp2=smp+smp4;
	smp3=smp+smp5;
    SetWindowPos(hwnd,HWND_TOP,0,0,smp3,smp2, SWP_NOMOVE);
    xy_txt = {0,smp,0, 0};
    _snprintf(str_out2, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);

    strcpy(str_out4, str_out2);
    strcat(str_out4, str_out3);

}else if(GetAsyncKeyState(0x53)){
    smp+=1;
	smp2=smp+smp4;
	smp3=smp+smp5;
    SetWindowPos(hwnd,HWND_TOP,0,0,smp3,smp2, SWP_NOMOVE);
    xy_txt = {0,smp,0, 0};
    _snprintf(str_out2, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);

    strcpy(str_out4, str_out2);
    strcat(str_out4, str_out3);

}else{
_snprintf(str_out, MAX_PATH-1,"PASTING: %d, %d, %d",Ro,Go,Bo);
strcpy(str_out4, str_out);
strcat(str_out4, str_out3);
}
}else{
    _snprintf(str_out2, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);

    strcpy(str_out4, str_out2);
    strcat(str_out4, str_out3);
}


    b= GetCursorPos(&p);

 hdc = GetDC(NULL);

HDC hDest = CreateCompatibleDC(hdc);

HBITMAP hbCapture=  CreateCompatibleBitmap(hdc, smp, smp);
SelectObject(hDest, hbCapture);

BitBlt(hDest, 0,0, smp, smp, hdc, p.x-0.5*smp,p.y-0.5*smp, SRCCOPY);

ReleaseDC(NULL, hdc);
DeleteDC(hDest);

       hdc = BeginPaint(hwnd, &ps);
FillRect(hdc, &ps.rcPaint, hBrush);
  DrawText(hdc,str_out4, -1, &xy_txt,DT_NOCLIP);
      HDC hdcCaptureBmp = CreateCompatibleDC(hdc);
      oldObject = SelectObject(hdcCaptureBmp, hbCapture);

      BitBlt(hdc, 0, 0, smp, smp, hdcCaptureBmp, 0,0, SRCCOPY);

      SelectObject(hdcCaptureBmp, oldObject);

double red, green, blue;
int col_int;
int Rd,Gr,Bl,grey;
double mn,mx,diff,sat,hue_d;
int colours_cnt[2][13]={{0,0,0,0,0,0,0,0,0,0,0,0,0},{0,1,2,3,4,5,6,7,8,9,10,11,12}};
//double colours_sc[13]={0,0,0,0,0,0,0,0,0,0,0,0,0};
double colours_sats[13]={0,0,0,0,0,0,0,0,0,0,0,0,0};
double colours_hues[13]={0,0,0,0,0,0,0,0,0,0,0,0,0};
int colours_R[13]={0,0,0,0,0,0,0,0,0,0,0,0,0};
int colours_G[13]={0,0,0,0,0,0,0,0,0,0,0,0,0};
int colours_B[13]={0,0,0,0,0,0,0,0,0,0,0,0,0};

 for (int x=0;x<smp;x++){
 for (int y=0;y<smp;y++){

        color = GetPixel(hdc,x,y);

 Rd=GetRValue(color);
 Gr=GetGValue(color);
 Bl=GetBValue(color);

            red= (double)(Rd)/255.0;
            green= (double)(Gr)/255.0;
            blue= (double)(Bl)/255.0;

  grey=((Rd==Gr)&&(Gr==Bl))?1:0;
  mn=MIN(red,MIN(green,blue));
  mx=MAX(red,MAX(green,blue));
  diff=mx-mn;
  sat=(mx==0)?0:diff/mx;
  //sc=0.5*(mn+sat);


if (grey==0){

if ((Rd>Gr)&&(Rd>Bl)){
    hue_d =(green - blue) / diff;
}else if ((Gr>Rd)&&(Gr>Bl)){
    hue_d = 2.0 + (blue - red) / diff;
}else{
    hue_d = 4.0 + (red - green) / diff;
}
    hue_d*=60;
    hue_d =(hue_d < 0)?hue_d + 360:hue_d;

    int hue=floor(hue_d*10);


if((hue>=3525)||(((hue>=0) && (hue<75)))){
colours_cnt[0][1]+=1;
col_int=1;
}else if((hue>=75) && (hue<375)){
colours_cnt[0][2]+=1;
col_int=2;
}else if((hue>=375) && (hue<675)){
colours_cnt[0][3]+=1;
col_int=3;
}else if((hue>=675) && (hue<975)){
colours_cnt[0][4]+=1;
col_int=4;
}else if((hue>=975) && (hue<1275)){
colours_cnt[0][5]+=1;
col_int=5;
}else if((hue>=1275) && (hue<1575)){
colours_cnt[0][6]+=1;
col_int=6;
}else if((hue>=1575) && (hue<1875)){
colours_cnt[0][7]+=1;
col_int=7;
}else if((hue>=1875) && (hue<2175)){
colours_cnt[0][8]+=1;
col_int=8;
}else if((hue>=2175) && (hue<2475)){
colours_cnt[0][9]+=1;
col_int=9;
}else if((hue>=2475) && (hue<3075)){
colours_cnt[0][10]+=1;
col_int=10;
}else if((hue>=3075) && (hue<3375)){
colours_cnt[0][11]+=1;
col_int=11;
}else if((hue>=3375) && (hue<3525)){
colours_cnt[0][12]+=1;
col_int=12;
}

}else{
colours_cnt[0][0]+=1;
col_int=0;
}


if (grey==1){
double mx=MAX(red,MAX(green,blue));
    if(mx>colours_sats[col_int] || colours_sats[0]==0){
        colours_hues[col_int]=0;
        colours_sats[col_int]=mx;
            colours_R[col_int]=Rd;
    colours_B[col_int]=Bl;
    colours_G[col_int]=Gr;
    }

}else{
    if((sat<colours_sats[col_int]) || (colours_cnt[0][col_int]==1)){
    colours_sats[col_int]=sat;
        colours_hues[col_int]=hue_d;
            colours_R[col_int]=Rd;
    colours_G[col_int]=Gr;
    colours_B[col_int]=Bl;
    }
}

/*

if (colours_cnt[0][0]==0 || (sat<colours_sats[col_int])){
    colours_hues[col_int]=hue_d;
    //colours_sc[col_int]=sc;
    colours_sats[col_int]=sat;
    colours_R[col_int]=Rd;
    colours_G[col_int]=Gr;
    colours_B[col_int]=Bl;
}
*/


 }
}

DeleteObject(hbCapture);
DeleteObject(oldObject);
DeleteDC(hdcCaptureBmp);

twoD_sort_asc(2,13,colours_cnt,0); //Sort by frequency of colours

int col_range=0;

int out_col;

    if(colours_cnt[1][0]==0){
        out_col=(colours_cnt[0][1]==0)?0:colours_cnt[1][1];
    }else{
        out_col=colours_cnt[1][0];
    }

   sat_out=colours_sats[out_col];
    Ro=colours_R[out_col];
    Go=colours_G[out_col];
    Bo=colours_B[out_col];

if ((out_col==0)||(sat_out==0)){
_snprintf(str_out3, MAX_PATH-1,"\nSaturation: %.1f; Greyscale",0);
}else{
        hue_out=colours_hues[out_col];

    switch(out_col)
    {
        case 1:
        nomin_hue="Red";
        break;
        case 2:
        nomin_hue="Orange/Brown";
        break;
        case 3:
        nomin_hue="Yellow";
        break;
        case 4:
        nomin_hue="Chartreuse/Lime";
        break;
        case 5:
        nomin_hue="Green";
        break;
        case 6:
        nomin_hue="Spring Green";
        break;
        case 7:
        nomin_hue="Cyan";
        break;
        case 8:
        nomin_hue="Azure/Sky blue";
        break;
        case 9:
        nomin_hue="Blue";
        break;
        case 10:
        nomin_hue="Violet/Purple";
        break;
        case 11:
        nomin_hue="Magenta/Pink";
        break;
        case 12:
        nomin_hue="Reddish Pink";
        break;
        default:
            ;
    }

_snprintf(str_out3, MAX_PATH-1,"\nSaturation: %.1f; %s (%.1f°)",sat_out*100,nomin_hue,hue_out);
}

_snprintf(str_out2, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);

   if(GetAsyncKeyState(VK_SHIFT) && !(GetAsyncKeyState(VK_CONTROL)) && !(GetAsyncKeyState(VK_MENU))){

_snprintf(str_out, MAX_PATH-1,"PASTING: %d, %d, %d",Ro,Go,Bo);

strcpy(str_out5, str_out);
strcat(str_out5, str_out3);
const size_t len = strlen(str_out2) + 1;
HGLOBAL hGloblal =  GlobalAlloc(GMEM_MOVEABLE, len);
memcpy(GlobalLock(hGloblal), str_out2, len);
GlobalUnlock(hGloblal);
OpenClipboard(hwnd);
EmptyClipboard();
SetClipboardData(CF_TEXT, hGloblal);
CloseClipboard();
  DrawText(hdc,str_out5, -1, &xy_txt, DT_NOCLIP);

   }else{
       strcpy(str_out4, str_out2);
strcat(str_out4, str_out3);
       DrawText(hdc,str_out4, -1, &xy_txt,DT_NOCLIP);

   }

      EndPaint(hwnd, &ps);

        }

        break;
        case WM_MOUSEWHEEL :{
        	if (GET_WHEEL_DELTA_WPARAM(wParam) > 0)
		{
			smp+=1;
		} else if (GET_WHEEL_DELTA_WPARAM(wParam) < 0) {
			smp=(smp>=2)?smp-1:smp;
		}
        smp2=smp+smp4;
        smp3=smp+smp5;
		SetWindowPos(hwnd,HWND_TOP,0,0,smp3,smp2, SWP_NOMOVE);
        }
        break;
        case WM_TIMER:
            InvalidateRect(hwnd, nullptr, false);
            break;
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
        default:
            return DefWindowProc(hwnd, message, wParam, lParam);
    }
    return 0;
}

ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEX wcex;
    wcex.cbSize = sizeof(WNDCLASSEX);
    wcex.style = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc = WndProc;
    wcex.cbClsExtra = 0;
    wcex.cbWndExtra = 0;
    wcex.hInstance = hInstance;
    wcex.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wcex.hCursor = LoadCursor(NULL, IDC_ARROW);
    wcex.hbrBackground = hBrush;
    wcex.lpszMenuName = NULL;
    wcex.lpszClassName = "rgbClass";
    wcex.hIconSm = NULL;
    return RegisterClassEx(&wcex);
}

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{

RECT sz = {0, 0, smp3+smp+263, smp2+smp+13};
        /*{x-coordinate of the upper-left corner of the rectangle, y-coordinate of the upper-left corner of the rectangle,
    x-coordinate of the lower-right corner of the rectangle, y-coordinate of the lower-right corner of the rectangle}
    */
    AdjustWindowRect(&sz, WS_OVERLAPPEDWINDOW, TRUE);
    hwnd = CreateWindow("rgbClass", "RGB for white point", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, sz.right - sz.left, sz.bottom - sz.top,
        NULL, NULL, hInstance, NULL);

    if(!hwnd)
    {
        return FALSE;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);
    return TRUE;
}

int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    MyRegisterClass(hInstance);
    if(!InitInstance(hInstance, nCmdShow))
    {
        return FALSE;
    }

   SetTimer(hwnd, 1, USER_TIMER_MINIMUM, nullptr);

                  if(IsWindowVisible(hwnd)==true){
            SetWindowPos(
  hwnd,
  (HWND) HWND_TOPMOST,
  0, 0, 0, 0,
  SWP_NOMOVE | SWP_NOSIZE );
               }

    MSG msg;
    while(GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}
