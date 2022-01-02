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

int smp = 10;
int smp2 = 0;
int smp3 = 0;
int smp4 = 72;
int smp5 = 332;

char* out_line="";

HWND hwnd;
POINT p;
BOOL b;
HBRUSH hBrush = CreateSolidBrush(RGB(0,0,0));
PAINTSTRUCT ps;
u_int rfsh = 7;
HDC hdc;
DEVMODE dm = {0};

void get_RGB_at_x_y(const BYTE* bit_ptr, int x, int y, int RGB[3], int b_wdt){
    int index=4*(y*b_wdt+x);

    RGB[2]=(int)bit_ptr[index];
    RGB[1]=(int)bit_ptr[index+1];
    RGB[0]=(int)bit_ptr[index+2];

}

void renderWnd(HWND hwnd, PAINTSTRUCT ps) {

RECT  xy_txt = {0,smp,0, 0};

b= GetCursorPos(&p);
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

BitBlt(hDest, 0,0, smp, smp, hdc, round(p.x-0.5*smp),round(p.y-0.5*smp), SRCCOPY);

ReleaseDC(NULL, hdc);
DeleteDC(hDest);

hdc = BeginPaint(hwnd, &ps);

HDC hdcCaptureBmp = CreateCompatibleDC(hdc);
HGDIOBJ hdcBMPObj = SelectObject(hdcCaptureBmp, hbCapture);

		double avgRGB[3]={0,0,0};
		double cnt=0;
        for(int x=0; x<smp; x++){
        for(int y=0; y<smp; y++){
            int currRGB[3];
            get_RGB_at_x_y(scr_bit_ptr,x,y,currRGB,smp);
			avgRGB[0]+=(double)currRGB[0];
			avgRGB[1]+=(double)currRGB[1];
			avgRGB[2]+=(double)currRGB[2];
			cnt+=1;
        }
        }

        double red = avgRGB[0]/cnt;
        double green = avgRGB[1]/cnt;
        double  blue = avgRGB[2]/cnt;

        int  redInt = round(red);
        int  greenInt = round(green);
        int  blueInt =  round(blue);

        double  mx = MAX(red, MAX(green, blue));
        double  sat = (mx == 0) ? 0 : ((mx - MIN(red, MIN(green, blue))) / mx) * 100;

        int grey = ((red == green) && (green == blue)) ? 1 : 0;
        double  mn = MIN(red, MIN(green, blue));
        double diff = mx - mn;
        char* nomin_hue = "Greyscale";
        double hue_d;
        int out_col=0;
        double hue_out = 0;
    if (grey == 0) {

            if ((red >= green) && (red >= blue)) {
                hue_d = (green - blue) / diff;
            } else if ((green >= red) && (green >= blue)) {
                hue_d = 2.0 + (blue - red) / diff;
            } else {
                hue_d = 4.0 + (red - green) / diff;
            }
            hue_d *= 60;
            hue_d = (hue_d < 0) ? hue_d + 360 : hue_d;
            hue_out = hue_d;
            int hue = floor(hue_d * 10);
            if ((hue >= 3525) || (((hue >= 0) && (hue < 75)))) {
                out_col = 1;
            } else if ((hue >= 75) && (hue < 375)) {
                out_col = 2;
            } else if ((hue >= 375) && (hue < 675)) {
                out_col = 3;
            } else if ((hue >= 675) && (hue < 975)) {
                out_col = 4;
            } else if ((hue >= 975) && (hue < 1275)) {
                out_col = 5;
            } else if ((hue >= 1275) && (hue < 1575)) {
                out_col = 6;
            } else if ((hue >= 1575) && (hue < 1875)) {
                out_col = 7;
            } else if ((hue >= 1875) && (hue < 2175)) {
                out_col = 8;
            } else if ((hue >= 2175) && (hue < 2475)) {
                out_col = 9;
            } else if ((hue >= 2475) && (hue < 3075)) {
                out_col = 10;
            } else if ((hue >= 3075) && (hue < 3375)) {
                out_col = 11;
            } else if ((hue >= 3375) && (hue < 3525)) {
                out_col = 12;
            }

            switch (out_col) {
            case 1:
                nomin_hue = "Red";
                break;
            case 2:
                nomin_hue = "Orange/Brown";
                break;
            case 3:
                nomin_hue = "Yellow";
                break;
            case 4:
                nomin_hue = "Chartreuse/Lime";
                break;
            case 5:
                nomin_hue = "Green";
                break;
            case 6:
                nomin_hue = "Spring Green";
                break;
            case 7:
                nomin_hue = "Cyan";
                break;
            case 8:
                nomin_hue = "Azure/Sky blue";
                break;
            case 9:
                nomin_hue = "Blue";
                break;
            case 10:
                nomin_hue = "Violet/Purple";
                break;
            case 11:
                nomin_hue = "Magenta/Pink";
                break;
            case 12:
                nomin_hue = "Reddish Pink";
                break;
            }
        }

    int c1;

    if(grey==0){
         c1 = asprintf( & out_line, "%d, %d, %d\nSaturation: %.1f; %s \(%.1f%c) - [%dx%d]",redInt, greenInt, blueInt, sat, nomin_hue, hue_out,176,smp,smp);
    }else{
        c1 = asprintf( & out_line, "%d, %d, %d\nSaturation: %.1f; %s - [%dx%d]", redInt, greenInt, blueInt, sat, nomin_hue,smp,smp);
    }

    char* str_out=(char*)malloc((c1+1)*sizeof(char));
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            hBrush = CreateSolidBrush(RGB(redInt,greenInt,blueInt));
            FillRect(hdc, &ps.rcPaint, hBrush);
            DrawText(hdc, str_out, -1, & xy_txt, DT_NOCLIP);
            free(str_out);
            free(out_line);
            BitBlt(hdc, 0, 0, smp, smp, hdcCaptureBmp, 0,0, SRCCOPY);

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
        if (GET_WHEEL_DELTA_WPARAM(wParam) > 0){
			smp+=1;
		}else if (GET_WHEEL_DELTA_WPARAM(wParam) < 0) {
            smp=(smp>=2)?smp-1:smp;
		}
        smp2=smp+smp4;
        smp3=smp+smp5;
		SetWindowPos(hwnd,HWND_TOP,0,0,smp3,smp2, SWP_NOMOVE);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {

    switch(message) {

            case WM_PAINT:
            renderWnd(hwnd, ps);
            return 0L;
            break;
        case WM_MOUSEWHEEL:
        mousewheel_hdl(wParam);
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

RECT sz = {0, 0, smp3+smp+316, smp2+smp+10};
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
