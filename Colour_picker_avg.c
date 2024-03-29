#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <math.h>
#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

int vscprintf(const char * format, va_list ap) {
    va_list ap_copy;
    va_copy(ap_copy, ap);
    int retval = vsnprintf(NULL, 0, format, ap_copy);
    va_end(ap_copy);
    return retval;
}

int vasprintf(char ** strp,
    const char * format, va_list ap) {
    int len = vscprintf(format, ap);
    if (len == -1)
        return -1;
    char * str = (char * ) malloc((size_t) len + 1);
    if (!str)
        return -1;
    int retval = vsnprintf(str, len + 1, format, ap);
    if (retval == -1) {
        free(str);
        return -1;
    }
    * strp = str;
    return retval;
}

int asprintf(char ** strp,
    const char * format, ...) {
    va_list ap;
    va_start(ap, format);
    int retval = vasprintf(strp, format, ap);
    va_end(ap);
    return retval;
}

int smp = 5;
double smp_d = 5;

int mds=90; //min display size
double mds_d=90;

int osz=90;

int smp_r = 350;
int smp_b = 57;
int smp_b_xy = 23;

double actuWdt, actuHgt, pWdt, pHgt, mPos_x, mPos_y, w_ratio, h_ratio;

char* out_line="";

HWND hwnd;
POINT p;
BOOL b;
HBRUSH hBrush_white = CreateSolidBrush(RGB(0xFF,0xFF,0xFF));
PAINTSTRUCT ps;
u_int rfsh = 7;
HDC hdc;
DEVMODE dm;
int altKy=0;

RECT  xy_txt = {0,osz,MAX(osz,smp_r), osz+smp_b+smp_b_xy};

LRESULT CALLBACK keyboardHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
    PKBDLLHOOKSTRUCT hooked_key = (PKBDLLHOOKSTRUCT) lParam;

    if ((wParam == WM_SYSKEYDOWN) || (wParam == WM_KEYDOWN)) {
        if (hooked_key -> vkCode == VK_LMENU || hooked_key -> vkCode == VK_RMENU || hooked_key -> vkCode == VK_MENU){
            altKy = 1;
        }

    } else if ((wParam == WM_SYSKEYUP) || (wParam == WM_KEYUP)) {
        if (hooked_key -> vkCode == VK_LMENU || hooked_key -> vkCode == VK_RMENU || hooked_key -> vkCode == VK_MENU){
            altKy = 0;
        }
    }

    return CallNextHookEx(NULL, nCode, wParam, lParam);
}

void get_RGB_at_x_y_dbl(const BYTE* bit_ptr, int x, int y, double RGB[3], int b_wdt){
    int index=4*(y*b_wdt+x);

    RGB[2]=(double)bit_ptr[index];
    RGB[1]=(double)bit_ptr[index+1];
    RGB[0]=(double)bit_ptr[index+2];

}

void renderWnd(HWND hwnd, PAINTSTRUCT ps) {

b=GetCursorPos(&p);

if(w_ratio!=1){
    mPos_x=(double)(p.x);
    p.x=MIN(pWdt,MAX(0,round(mPos_x*w_ratio)));
}

if(h_ratio!=1){
    mPos_y=(double)(p.y);
    p.y=MIN(pHgt,MAX(0,round(mPos_y*h_ratio)));
}

hdc = GetDC(NULL);
HDC hDest = CreateCompatibleDC(hdc);
BYTE* scr_bit_ptr;
BITMAPINFO bmi;
ZeroMemory(&bmi, sizeof(BITMAPINFO));
bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
bmi.bmiHeader.biWidth = smp;
bmi.bmiHeader.biHeight = -smp;  //negative so (0,0) is at top left
bmi.bmiHeader.biPlanes = 1;
bmi.bmiHeader.biBitCount = 32;

HDC bmp_dc = CreateCompatibleDC(NULL);
HBITMAP hbCapture = CreateDIBSection(bmp_dc, &bmi, DIB_RGB_COLORS, (void**)(&scr_bit_ptr), NULL, 0);

HGDIOBJ destCap=SelectObject(hDest, hbCapture);

StretchBlt(hDest, 0,0, smp, smp, hdc,round(p.x-0.5*smp),round(p.y-0.5*smp) ,smp, smp, SRCCOPY);

ReleaseDC(NULL, hdc);
DeleteDC(hDest);

hdc = BeginPaint(hwnd, &ps);

HDC hdcCaptureBmp = CreateCompatibleDC(hdc);
HGDIOBJ hdcBMPObj = SelectObject(hdcCaptureBmp, hbCapture);

		double avgRGB[3]={0,0,0};
		double cnt=0;
        for(int x=0; x<smp; x++){
        for(int y=0; y<smp; y++){
            double currRGB[3];
            get_RGB_at_x_y_dbl(scr_bit_ptr,x,y,currRGB,smp);
			avgRGB[0]+=currRGB[0];
			avgRGB[1]+=currRGB[1];
			avgRGB[2]+=currRGB[2];
			cnt+=1;
        }
        }

        double red = avgRGB[0]/cnt;
        double green = avgRGB[1]/cnt;
        double  blue = avgRGB[2]/cnt;

        int  redInt = round(red);
        int  greenInt = round(green);
        int  blueInt =  round(blue);

        double  mn = MIN(red, MIN(green, blue));
        double  mx = MAX(red, MAX(green, blue));
        double chr=mx-mn;
        double  sat_out = (mx == 0) ? 0 : (chr / mx) * 100;
        double  val_out = mx/2.55;
        double  chr_out = chr/2.55;

        int grey = ((red == green) && (green == blue)) ? 1 : 0;

        char* nomin_hue = "Greyscale";
        double hue_d;
        double hue_out = 0;
    if (grey == 0) {

            if ((red >= green) && (red >= blue)) {
                hue_d = (green - blue) / chr;
            } else if ((green >= red) && (green >= blue)) {
                hue_d = 2.0 + (blue - red) / chr;
            } else {
                hue_d = 4.0 + (red - green) / chr;
            }
            hue_d =(hue_d==6)?0:hue_d;
            hue_d *= 60;
            hue_d = (hue_d < 0) ? hue_d + 360 : hue_d;
            double hue_col = floor(hue_d*10);
            hue_out = hue_col/10.0;
            int hue = round(hue_col);

            if ((hue >= 3525) || (((hue >= 0) && (hue < 75)))) {
                nomin_hue = "Red";
            } else if ((hue >= 75) && (hue < 375)) {
                nomin_hue = "Orange/Brown";
            } else if ((hue >= 375) && (hue < 675)) {
                nomin_hue = "Yellow";
            } else if ((hue >= 675) && (hue < 975)) {
                nomin_hue = "Chartreuse/Lime";
            } else if ((hue >= 975) && (hue < 1275)) {
                nomin_hue = "Green";
            } else if ((hue >= 1275) && (hue < 1575)) {
                nomin_hue = "Spring Green";
            } else if ((hue >= 1575) && (hue < 1875)) {
                nomin_hue = "Cyan";
            } else if ((hue >= 1875) && (hue < 2175)) {
                nomin_hue = "Azure/Sky blue";
            } else if ((hue >= 2175) && (hue < 2475)) {
                nomin_hue = "Blue";
            } else if ((hue >= 2475) && (hue < 3075)) {
                nomin_hue = "Violet/Purple";
            } else if ((hue >= 3075) && (hue < 3375)) {
                nomin_hue = "Magenta/Pink";
            } else if ((hue >= 3375) && (hue < 3525)) {
                nomin_hue = "Reddish Pink";
            }
        }

    int c1;

    if(grey==0){
        c1 = asprintf( & out_line, "%d, %d, %d\n%s (%.1f%c) - [%d: %dx%d] (x:%d, y:%d)\n      Saturation: %.1f\n               Value: %.1f\nChroma: %.1f",redInt, greenInt, blueInt, nomin_hue, hue_out,176,mds,smp,smp,p.x,p.y,sat_out, val_out,chr_out);
    }else{
        c1 = asprintf( & out_line, "%d, %d, %d\n%s - [%d: %dx%d] (x:%d, y:%d)\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", redInt, greenInt, blueInt, nomin_hue,mds,smp,smp,p.x,p.y,sat_out, val_out,chr_out);
    }

            char str_out[c1+1];
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            HBRUSH hBrush = CreateSolidBrush(RGB(redInt,greenInt,blueInt));
            FillRect(hdc, &ps.rcPaint, hBrush);
           SetBkColor(hdc,RGB(255,255,255));
           SetTextColor(hdc,RGB(0,0,0));

            FillRect(hdc, &xy_txt, hBrush_white);
            DrawText(hdc, str_out, -1, &xy_txt, DT_NOCLIP);
            free(out_line);
            StretchBlt(hdc, 0,0, osz, osz, hdcCaptureBmp,0,0,smp, smp, SRCCOPY);

DeleteObject(hBrush);
DeleteObject(hbCapture);
DeleteObject(destCap);
DeleteObject(hdcBMPObj);
DeleteDC(hDest);
DeleteDC(bmp_dc);
DeleteDC(hdcCaptureBmp);
ReleaseDC(NULL, hdc);
DeleteDC(hdc);
EndPaint(hwnd, &ps);
}

void mousewheel_hdl(WPARAM wParam) {

    dm = {0};
    dm.dmSize = sizeof(DEVMODE);
    if (EnumDisplaySettings(NULL, ENUM_CURRENT_SETTINGS, & dm)) {
        rfsh = round(1000/((double)(dm.dmDisplayFrequency)));
    }

    pWdt=(double)dm.dmPelsWidth-1;
    pHgt=(double)dm.dmPelsHeight-1;

    HDC hdc_wnd=GetDC(hwnd);
    actuWdt=(double)(GetDeviceCaps(hdc_wnd,HORZRES)-1);
    actuHgt=(double)(GetDeviceCaps(hdc_wnd,VERTRES)-1);

    int mv_rfrsh=(double)(GetDeviceCaps(hdc_wnd,VREFRESH));

    ReleaseDC(hwnd,hdc_wnd);
    DeleteDC(hdc_wnd);

    rfsh=(mv_rfrsh==0 || mv_rfrsh==1)?rfsh:round(1000/((double)(mv_rfrsh)));

    w_ratio=(pWdt==actuWdt)?1:pWdt/actuWdt;
    h_ratio=(pHgt==actuHgt)?1:pHgt/actuHgt;

    b=GetCursorPos(&p);

    if(w_ratio!=1){
        mPos_x=(double)(p.x);
        p.x=MIN(pWdt,MAX(0,round(mPos_x*w_ratio)));
    }

    if(h_ratio!=1){
        mPos_y=(double)(p.y);
        p.y=MIN(pHgt,MAX(0,round(mPos_y*h_ratio)));
    }

    if(altKy==0){
        if (GET_WHEEL_DELTA_WPARAM(wParam) > 0){
			smp+=1;
			smp_d+=1;
		}else if (GET_WHEEL_DELTA_WPARAM(wParam) < 0) {
            smp=(smp>=2)?smp-1:smp;
            smp_d=(double)smp;
		}
    }else{
        if (GET_WHEEL_DELTA_WPARAM(wParam) > 0){
			mds+=1;
			mds_d+=1;
		}else if (GET_WHEEL_DELTA_WPARAM(wParam) < 0) {
            mds=(mds>=2)?mds-1:mds;
            mds_d=(double)mds;
		}
    }


        osz=MAX(smp,round(smp_d*ceil(mds_d/smp_d)));

double nw_cx=MAX(osz,smp_r);
double nw_cy=osz+smp_b+62;

		SetWindowPos(hwnd,HWND_TOP,0,0,nw_cx+16,nw_cy, SWP_NOMOVE);

		double xy_diff=xy_txt.bottom-xy_txt.top;
		xy_txt.top=osz;
		xy_txt.bottom=osz+xy_diff;
		xy_txt.right=nw_cx;

}

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {

switch(message) {

            case WM_PAINT:
            renderWnd(hwnd, ps);
            return 0L;
            break;
        case WM_MOUSEWHEEL:
        mousewheel_hdl(wParam);
        return 0L;
        break;
            case WM_TIMER:
                InvalidateRect(hwnd, nullptr, false);
                return 0L;
                break;
        case WM_DESTROY:
            PostQuitMessage(0);
        break;
            default:
                return DefWindowProc(hwnd, message, wParam, lParam);
    }
}

ATOM MyRegisterClass(HINSTANCE hInstance)
{
    HICON hIconLarge, hIconSmall;
    ExtractIconEx("shell32.dll",161,&hIconLarge, &hIconSmall, 1);
    WNDCLASSEX wcex;
    wcex.cbSize = sizeof(WNDCLASSEX);
    wcex.style = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc = WndProc;
    wcex.cbClsExtra = 0;
    wcex.cbWndExtra = 0;
    wcex.hInstance = hInstance;
    wcex.hIcon = hIconLarge;
    wcex.hCursor = LoadCursor(NULL, IDC_ARROW);
    wcex.hbrBackground = hBrush_white;
    wcex.lpszMenuName = NULL;
    wcex.lpszClassName = "rgbClass";
    wcex.hIconSm = NULL;
    return RegisterClassEx(&wcex);
}

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{

RECT sz = {0, 0, MAX(osz,smp_r), osz+smp_b};
        /*{x-coordinate of the upper-left corner of the rectangle, y-coordinate of the upper-left corner of the rectangle,
    x-coordinate of the lower-right corner of the rectangle, y-coordinate of the lower-right corner of the rectangle}
    */
    AdjustWindowRect(&sz, WS_OVERLAPPEDWINDOW, TRUE);
    hwnd = CreateWindow("rgbClass", "Colour picker avg", WS_OVERLAPPEDWINDOW,
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
int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    MyRegisterClass(hInstance);
    if (!InitInstance(hInstance, nCmdShow)) {
        return FALSE;
    }

    dm = {0};
    dm.dmSize = sizeof(DEVMODE);
    if (EnumDisplaySettings(NULL, ENUM_CURRENT_SETTINGS, & dm)) {
        rfsh = round(1000/((double)(dm.dmDisplayFrequency)));
    }

    pWdt=(double)dm.dmPelsWidth-1;
    pHgt=(double)dm.dmPelsHeight-1;

    HDC hdc_wnd=GetDC(hwnd);
    actuWdt=(double)(GetDeviceCaps(hdc_wnd,HORZRES)-1);
    actuHgt=(double)(GetDeviceCaps(hdc_wnd,VERTRES)-1);

    int mv_rfrsh=(double)(GetDeviceCaps(hdc_wnd,VREFRESH));

    ReleaseDC(hwnd,hdc_wnd);
    DeleteDC(hdc_wnd);

    rfsh=(mv_rfrsh==0 || mv_rfrsh==1)?rfsh:round(1000/((double)(mv_rfrsh)));

    w_ratio=(pWdt==actuWdt)?1:pWdt/actuWdt;
    h_ratio=(pHgt==actuHgt)?1:pHgt/actuHgt;

    b=GetCursorPos(&p);

    if(w_ratio!=1){
        mPos_x=(double)(p.x);
        p.x=MIN(pWdt,MAX(0,round(mPos_x*w_ratio)));
    }

    if(h_ratio!=1){
        mPos_y=(double)(p.y);
        p.y=MIN(pHgt,MAX(0,round(mPos_y*h_ratio)));
    }

    HHOOK hKeyboardHook;

    hKeyboardHook = SetWindowsHookEx(
        WH_KEYBOARD_LL,
        keyboardHookProc,
        hInstance,
        0);

   SetTimer(hwnd, 1, rfsh, nullptr);
    if (IsWindowVisible(hwnd) == true) {
        SetWindowPos(
            hwnd,
            (HWND) HWND_TOPMOST,
            0, 0, 0, 0,
            SWP_NOMOVE | SWP_NOSIZE);
    }

    MSG msg;
    while (GetMessage( & msg, NULL, 0, 0)) {
        TranslateMessage( & msg);
        DispatchMessage( & msg);
    }
    return (int) msg.wParam;
}
