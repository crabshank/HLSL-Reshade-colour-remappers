#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <math.h>
#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

HINSTANCE hInst;
HWND hwnd;
POINT p;
POINT p_fixed;
BOOL b;

char str_top[MAX_PATH]={0};
char str_bottom[MAX_PATH]={0};
char str_both[MAX_PATH]={0};
char str_paste[MAX_PATH]={0};

int Ro=0;
int Go=0;
int Bo=0;
int smp = 10;
int smp2 = 0;
int smp3 = 0;
int smp4 = 72;
int smp5 = 297;

int mode=0; //0: normal, 1: fixed cursor

RECT  xy_txt = {0,smp,0, 0};

void renderWnd(HWND hwnd, PAINTSTRUCT ps){
int Rd,Gr,Bl,grey;

char* nomin_hue="";
double sat_out=0;
double hue_out=0;
int out_col=0;
COLORREF color;
HBRUSH hBrush = CreateSolidBrush(RGB(0,0,0));


      if(GetAsyncKeyState(VK_SHIFT) && !(GetAsyncKeyState(VK_CONTROL)) && !(GetAsyncKeyState(VK_MENU))){
if(GetAsyncKeyState(0x41)){
    smp=(smp>=2)?smp-1:smp;
	smp2=smp+smp4;
	smp3=smp+smp5;
    SetWindowPos(hwnd,HWND_TOP,0,0,smp3,smp2, SWP_NOMOVE);
    xy_txt = {0,smp,0, 0};
    _snprintf(str_top, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);

    strcpy(str_both, str_top);
    strcat(str_both, str_bottom);

}else if(GetAsyncKeyState(0x53)){
    smp+=1;
	smp2=smp+smp4;
	smp3=smp+smp5;
    SetWindowPos(hwnd,HWND_TOP,0,0,smp3,smp2, SWP_NOMOVE);
    xy_txt = {0,smp,0, 0};
    _snprintf(str_top, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);

    strcpy(str_both, str_top);
    strcat(str_both, str_bottom);

}else{
_snprintf(str_top, MAX_PATH-1,"PASTING: %d, %d, %d",Ro,Go,Bo);
    strcpy(str_both, str_top);
    strcat(str_both, str_bottom);

}
}else if(!GetAsyncKeyState(VK_SHIFT) && (GetAsyncKeyState(VK_CONTROL)) && (GetAsyncKeyState(VK_MENU)) && mode==1){ //choose fixed pixel
                    b= GetCursorPos(&p);
                        p_fixed.x=p.x;
                        p_fixed.y=p.y;
}else{
    _snprintf(str_top, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);

    strcpy(str_both, str_top);
    strcat(str_both, str_bottom);
}

if(mode!=1){
	b= GetCursorPos(&p);
	p_fixed.x=p.x;
	p_fixed.y=p.y;
	}
	HDC hdcMemDC=NULL;
	HBITMAP hbmScreen=NULL;

	HDC hdcScreen=GetDC(NULL);
	HDC hdcWindow=GetDC(hwnd);
	hdcMemDC=CreateCompatibleDC(hdcWindow);
	if(!hdcMemDC){
        goto done;
	}

    if(!BitBlt(hdcWindow, 0,0, 1,1, hdcScreen,p_fixed.x,p_fixed.y, SRCCOPY)){
        goto done;
    }
	hbmScreen=CreateCompatibleBitmap(hdcWindow,1,1);
	if(!hbmScreen){
        goto done;
	}
	SelectObject(hdcMemDC,hbmScreen);
    if(!BitBlt(hdcMemDC, 0,0, 1,1, hdcWindow,0,0, SRCCOPY)){
        goto done;
    }

            color = GetPixel(hdcWindow,0,0);
            Rd=GetRValue(color);
            Gr=GetGValue(color);
            Bl=GetBValue(color);
            hBrush = CreateSolidBrush(RGB(Rd,Gr,Bl));
            FillRect(hdcWindow, &ps.rcPaint, hBrush);

double red, green, blue;

double mn,mx,diff,hue_d;

     Ro=Rd;
     Go=Gr;
     Bo=Bl;

    red= (double)(Rd)/255.0;
    green= (double)(Gr)/255.0;
    blue= (double)(Bl)/255.0;

  grey=((Rd==Gr)&&(Gr==Bl))?1:0;
  mn=MIN(red,MIN(green,blue));
  mx=MAX(red,MAX(green,blue));
  diff=mx-mn;
  sat_out=(mx==0)?0:diff/mx;

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
    hue_out=hue_d;
    int hue=floor(hue_d*10);


if((hue>=3525)||(((hue>=0) && (hue<75)))){
out_col=1;
}else if((hue>=75) && (hue<375)){
out_col=2;
}else if((hue>=375) && (hue<675)){
out_col=3;
}else if((hue>=675) && (hue<975)){
out_col=4;
}else if((hue>=975) && (hue<1275)){
out_col=5;
}else if((hue>=1275) && (hue<1575)){
out_col=6;
}else if((hue>=1575) && (hue<1875)){
out_col=7;
}else if((hue>=1875) && (hue<2175)){
out_col=8;
}else if((hue>=2175) && (hue<2475)){
out_col=9;
}else if((hue>=2475) && (hue<3075)){
out_col=10;
}else if((hue>=3075) && (hue<3375)){
out_col=11;
}else if((hue>=3375) && (hue<3525)){
out_col=12;
}

}

if (grey==1){
_snprintf(str_top, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);
_snprintf(str_bottom, MAX_PATH-1,"\nSaturation: %.1f; Greyscale",0);
    strcpy(str_both, str_top);
    strcat(str_both, str_bottom);
}else{

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

_snprintf(str_bottom, MAX_PATH-1,"\nSaturation: %.1f; %s (%.1f°)",sat_out*100,nomin_hue,hue_out);
}

_snprintf(str_top, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);

   if(GetAsyncKeyState(VK_SHIFT) && !(GetAsyncKeyState(VK_CONTROL)) && !(GetAsyncKeyState(VK_MENU))){

    _snprintf(str_paste, MAX_PATH-1,"%d, %d, %d",Ro,Go,Bo);
    _snprintf(str_top, MAX_PATH-1,"PASTING: %d, %d, %d",Ro,Go,Bo);

    strcpy(str_both, str_top);
    strcat(str_both, str_bottom);
    const size_t len = strlen(str_paste) + 1;
    HGLOBAL hGloblal =  GlobalAlloc(GMEM_MOVEABLE, len);
    memcpy(GlobalLock(hGloblal), str_paste, len);
    GlobalUnlock(hGloblal);
    OpenClipboard(hwnd);
    EmptyClipboard();
    SetClipboardData(CF_TEXT, hGloblal);
    CloseClipboard();
    DrawText(hdcWindow,str_both, -1, &xy_txt, DT_NOCLIP);

}else if(!GetAsyncKeyState(VK_SHIFT) && (GetAsyncKeyState(VK_CONTROL)) && (GetAsyncKeyState(VK_MENU)) && mode==1){ //choose fixed pixel
    b= GetCursorPos(&p);
    p_fixed.x=p.x;
    p_fixed.y=p.y;
    _snprintf(str_top, MAX_PATH-1,"Setting fixed cursor position: %d, %d",p_fixed.x,p_fixed.y);
    strcpy(str_both, str_top);
    strcat(str_both, str_bottom);
    DrawText(hdcWindow,str_both, -1, &xy_txt,DT_NOCLIP);
}else if(mode==1){
    _snprintf(str_top, MAX_PATH-1,"Fixed cursor (x:%d, y:%d): %d, %d, %d",p_fixed.x,p_fixed.y,Ro,Go,Bo);

    strcpy(str_both, str_top);
    strcat(str_both, str_bottom);
    DrawText(hdcWindow,str_both, -1, &xy_txt, DT_NOCLIP);
}else{
    strcpy(str_both, str_top);
    strcat(str_both, str_bottom);
    DrawText(hdcWindow,str_both, -1, &xy_txt,DT_NOCLIP);

   }

	done:
	    DeleteObject(hbmScreen);
	    DeleteObject(hdcMemDC);
	    ReleaseDC(NULL,hdcScreen);
	    ReleaseDC(hwnd,hdcWindow);

}

void mousewheel_hdl(WPARAM wParam){
    if (GET_WHEEL_DELTA_WPARAM(wParam) > 0){
    smp+=1;
    xy_txt = {0,smp,0, 0};
        if(!GetAsyncKeyState(VK_SHIFT) && (GetAsyncKeyState(VK_CONTROL)) && !(GetAsyncKeyState(VK_MENU))){
            mode=(mode+1>1)?0:mode+1;
        }
    } else if (GET_WHEEL_DELTA_WPARAM(wParam) < 0) {
        smp=(smp>=2)?smp-1:smp;
        xy_txt = {0,smp,0, 0};
        if(!GetAsyncKeyState(VK_SHIFT) && (GetAsyncKeyState(VK_CONTROL)) && !(GetAsyncKeyState(VK_MENU))){
            mode=(mode-1<0)?1:mode-1;
        }
    }
    smp2=smp+smp4;
    smp3=smp+smp5;
    SetWindowPos(hwnd,HWND_TOP,0,0,smp3,smp2, SWP_NOMOVE);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{

    switch(message)
    {
            case WM_CREATE:
            SetTimer(hwnd, 1, USER_TIMER_MINIMUM, NULL);
            return 0L;
            break;
        case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc=BeginPaint(hwnd,&ps);
            renderWnd(hwnd,ps);
            EndPaint(hwnd, &ps);
            SetTimer(hwnd, 1, USER_TIMER_MINIMUM, NULL);
            return 0L;
        }
        break;
            case WM_MOUSEWHEEL :
                mousewheel_hdl(wParam);
                return 0L;
            break;
        case WM_TIMER:
            {
                KillTimer(hwnd,1);
                InvalidateRect(hwnd, nullptr, false);
                return 0L;
            }
        break;
            case WM_DESTROY:
                {
                    KillTimer(hwnd,1);
                    PostQuitMessage(0);
                    return 0L;
                }
            break;
        case WM_ERASEBKGND:
            return DefWindowProc(hwnd, message, wParam, lParam);
        break;
        default:
          return DefWindowProc(hwnd, message, wParam, lParam);
        break;
    }
    return DefWindowProc(hwnd, message, wParam, lParam);
}

ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEX wcex;
    wcex.cbSize = sizeof(WNDCLASSEX);
    wcex.style = CS_HREDRAW | CS_VREDRAW | CS_SAVEBITS;
    wcex.lpfnWndProc = WndProc;
    wcex.cbClsExtra = 0;
    wcex.cbWndExtra = 0;
    wcex.hInstance = hInstance;
    wcex.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wcex.hCursor = LoadCursor(NULL, IDC_ARROW);
    wcex.hbrBackground = NULL;
    wcex.lpszMenuName = NULL;
    wcex.lpszClassName = "rgbClass";
    wcex.hIconSm = NULL;
    return RegisterClassEx(&wcex);
}

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{

RECT sz = {0, 0, smp3+smp+273, smp2+smp+13};
        /*{x-coordinate of the upper-left corner of the rectangle, y-coordinate of the upper-left corner of the rectangle,
    x-coordinate of the lower-right corner of the rectangle, y-coordinate of the lower-right corner of the rectangle}
    */
    AdjustWindowRect(&sz, WS_OVERLAPPEDWINDOW, TRUE);
    hwnd = CreateWindow("rgbClass", "Colour picker", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, sz.right - sz.left, sz.bottom - sz.top,
        NULL, NULL, hInstance, NULL);

    if(!hwnd){
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
    if(!InitInstance(hInstance, nCmdShow)){
        return FALSE;
    }


if(IsWindowVisible(hwnd)==true){
    SetWindowPos(
    hwnd,
    (HWND) HWND_TOPMOST,
    0, 0, 0, 0,
    SWP_NOMOVE | SWP_NOSIZE);
}

    MSG msg;
    while(GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}
