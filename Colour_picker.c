#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <windows.h>
#include <math.h>

#define MAX(x, y)(((x) > (y)) ? (x) : (y))
#define MIN(x, y)(((x) < (y)) ? (x) : (y))

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

long minHgt = 104;
long minWdt = 410;

u_int rfsh = 7;

HINSTANCE hInst;
HWND hwnd;

int shiftKy = 0;
int ctrlKy = 0;
int F2Ky = 1;
int F2KyLast = 1;
int pastingNow = 0;

char * out_line = "";
char * paste_line = "";
char * nomin_hue = "Greyscale";

int redInt, greenInt, blueInt, red2, green2, blue2, grey, c0, c1;
double red, green, blue, mx, sat_out, chr_out, mn, diff, hue_d, hue_out, actuWdt, actuHgt, pWdt, pHgt, mPos_x, mPos_y, w_ratio, h_ratio;

COLORREF color;
POINT p;
POINT p_fixed;
POINT p_fixed2;
BOOL b;
PAINTSTRUCT ps;
HDC hdc_px, hdc_px_tmp, hdcWindow;
BYTE* px_bit_ptr;

DEVMODE dm = {0};
RECT xy_txt = {0,0,minWdt,minHgt};
/*{x-coordinate of the upper-left corner of the rectangle, y-coordinate of the upper-left corner of the rectangle,
  x-coordinate of the lower-right corner of the rectangle, y-coordinate of the lower-right corner of the rectangle}
  */

LRESULT CALLBACK keyboardHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
    PKBDLLHOOKSTRUCT hooked_key = (PKBDLLHOOKSTRUCT) lParam;

    if ((wParam == WM_SYSKEYDOWN) || (wParam == WM_KEYDOWN)) {
        if (hooked_key -> vkCode == VK_LSHIFT || hooked_key -> vkCode == VK_RSHIFT || hooked_key -> vkCode == VK_SHIFT) {
            shiftKy = 1;
        }
        if (hooked_key -> vkCode == VK_LCONTROL || hooked_key -> vkCode == VK_RCONTROL || hooked_key -> vkCode == VK_CONTROL) {
            ctrlKy = 1;
        }
        if (hooked_key -> vkCode == VK_F2) {
            F2KyLast = F2Ky;
            F2Ky = (F2Ky == 2) ? 0 : F2Ky + 1;
        }

    } else if ((wParam == WM_SYSKEYUP) || (wParam == WM_KEYUP)) {
        if (hooked_key -> vkCode == VK_LSHIFT || hooked_key -> vkCode == VK_RSHIFT || hooked_key -> vkCode == VK_SHIFT) {
            shiftKy = 0;
        }
        if (hooked_key -> vkCode == VK_LCONTROL || hooked_key -> vkCode == VK_RCONTROL || hooked_key -> vkCode == VK_CONTROL) {
            ctrlKy = 0;
        }
    }

    return CallNextHookEx(NULL, nCode, wParam, lParam);
}

void paster(HWND hwnd, char * str_paste) {

    const size_t len = strlen(str_paste) + 1;
    HGLOBAL hGloblal = GlobalAlloc(GMEM_MOVEABLE, len);
    memcpy(GlobalLock(hGloblal), str_paste, len);
    GlobalUnlock(hGloblal);
    OpenClipboard(hwnd);
    EmptyClipboard();
    SetClipboardData(CF_TEXT, hGloblal);
    CloseClipboard();
}

void renderWnd(HWND hwnd, PAINTSTRUCT ps) {

    if ((ctrlKy == 1 && F2Ky == 1) || (F2Ky == 2)) {
        b=GetCursorPos(&p);

        if(w_ratio!=1){
            mPos_x=(double)(p.x);
            p.x=MIN(pWdt,MAX(0,round(mPos_x*w_ratio)));
        }

        if(h_ratio!=1){
            mPos_y=(double)(p.y);
            p.y=MIN(pHgt,MAX(0,round(mPos_y*h_ratio)));
        }

        p_fixed.x = p.x;
        p_fixed.y = p.y;

    }

     hdc_px = GetDC(NULL);
     hdc_px_tmp = CreateCompatibleDC(NULL);
     hdcWindow = GetDC(hwnd);

    BITMAPINFO bmp_px;
	ZeroMemory(&bmp_px, sizeof(BITMAPINFO));
	bmp_px.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
	bmp_px.bmiHeader.biWidth = 1;
	bmp_px.bmiHeader.biHeight = -1;  //negative so (0,0) is at top left
	bmp_px.bmiHeader.biPlanes = 1;
	bmp_px.bmiHeader.biBitCount = 32;

	HBITMAP bmp_px_DIB=CreateDIBSection(hdc_px_tmp,&bmp_px,DIB_RGB_COLORS,(void**)(&px_bit_ptr),NULL,NULL);
    HGDIOBJ bmp_px_DIB_obj=SelectObject(hdc_px_tmp,bmp_px_DIB);
    BitBlt(hdc_px_tmp, 0, 0, 1, 1, hdc_px, p_fixed.x, p_fixed.y, SRCCOPY);

    redInt = (int)px_bit_ptr[2];
    greenInt = (int)px_bit_ptr[1];
    blueInt = (int)px_bit_ptr[0];

    //Works because 1x1

    red = ((double) redInt) / 255.0;
    green = ((double) greenInt) / 255.0;
    blue = ((double) blueInt) / 255.0;

    int redoCols = (((red2 != redInt) || (green2 != greenInt) || (blue2 != blueInt)) )? 1 : 0;
    int redo = ((redoCols==1) || (shiftKy == 1) || (F2Ky != F2KyLast) || (((ctrlKy == 1 && F2Ky == 1) || (F2Ky == 2)) && (p_fixed.x != p_fixed2.x || p_fixed.y != p_fixed2.y))) ? 1 : 0;

    F2KyLast = (F2Ky != F2KyLast) ? F2Ky : F2KyLast;

    if(redoCols==0){
            redInt = red2;
            greenInt = green2;
            blueInt = blue2;
    }else{

        int Rd = redInt;
        int Gr = greenInt;
        int Bl = blueInt;

        double  mn = MIN(Rd, MIN(Gr, Bl));
        double  mx = MAX(Rd, MAX(Gr, Bl));
        double chr_raw=mx-mn;
        double chr=chr_raw/255;
          sat_out = (mx == 0) ? 0 : ((mx-mn) / mx) * 100;
          chr_out = chr_raw/2.55;

        grey = ((Rd == Gr) && (Gr == Bl)) ? 1 : 0;

        nomin_hue = "Greyscale";
        hue_out=0;
    if (grey == 0) {

            if ((red >= green) && (red >= blue)) {
                hue_d = (green - blue) / chr;
            } else if ((green >= red) && (green >= blue)) {
                hue_d = 2.0 + (blue - red) / chr;
            } else {
                hue_d = 4.0 + (red - green) / chr;
            }
            hue_d *= 60;
            hue_d = (hue_d < 0) ? hue_d + 360 : hue_d;
            hue_out = hue_d;
            int hue = floor(hue_d * 10);
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
   }

        InvalidateRect(hwnd, nullptr, false);
        HBRUSH hBrush = CreateSolidBrush(RGB(redInt, greenInt, blueInt));
        FillRect(hdcWindow, & ps.rcPaint, hBrush);

    if(grey==0){
        if (shiftKy == 1) {
            c0 = asprintf( & paste_line, "%d, %d, %d", redInt, greenInt, blueInt);
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "PASTING (x:%ld, y:%ld): %d, %d, %d\n%s \(%.1f%c)\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, nomin_hue, hue_out,176, sat_out,chr_out);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "PASTING (<x:%ld, y:%ld>): %d, %d, %d\n%s \(%.1f%c)\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, nomin_hue, hue_out,176, sat_out,chr_out);
            } else {
                c1 = asprintf( & out_line, "PASTING (_x:%ld, y:%ld_): %d, %d, %d\n%s \(%.1f%c)\nSaturation: %.1f\n    Chroma: %.1f",p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, nomin_hue, hue_out,176, sat_out,chr_out);
            }

            char str_out[c1+1];
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            DrawText(hdcWindow, str_out, -1, & xy_txt, DT_NOCLIP);
            free(out_line);

            char str_paste[c0+1];
            strncpy(str_paste, paste_line, c0);
            str_paste[c0] = '\0';
            pastingNow = (pastingNow == 0) ? 1 : pastingNow;
            paster(hwnd, str_paste);
            free(paste_line);

        } else {
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "(x:%ld, y:%ld): %d, %d, %d\n%s \(%.1f%c)\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, nomin_hue, hue_out,176, sat_out,chr_out);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "(<x:%ld, y:%ld>): %d, %d, %d\n%s \(%.1f%c)\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, nomin_hue, hue_out,176, sat_out,chr_out);
            } else {
                c1 = asprintf( & out_line, "(_x:%ld, y:%ld_): %d, %d, %d\n%s \(%.1f%c)\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, nomin_hue, hue_out,176, sat_out,chr_out);
            }

            char str_out[c1+1];
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            DrawText(hdcWindow, str_out, -1, & xy_txt, DT_NOCLIP);
            free(out_line);
        }


    }else{
         //if grey:

        if (shiftKy == 1) {
            c0 = asprintf( & paste_line, "%d, %d, %d", redInt, greenInt, blueInt);
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "PASTING (x:%ld, y:%ld): %d, %d, %d\n%s\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt,  nomin_hue,sat_out,chr_out);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "PASTING (<x:%ld, y:%ld>): %d, %d, %d\n%s\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt,  nomin_hue,sat_out,chr_out);
            } else {
                c1 = asprintf( & out_line, "PASTING (_x:%ld, y:%ld_): %d, %d, %d\n%s\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt,  nomin_hue,sat_out,chr_out);
            }

            char str_out[c1+1];
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            DrawText(hdcWindow, str_out, -1, & xy_txt, DT_NOCLIP);
            free(out_line);

            char str_paste[c0+1];
            strncpy(str_paste, paste_line, c0);
            str_paste[c0] = '\0';
            pastingNow = (pastingNow == 0) ? 1 : pastingNow;
            paster(hwnd, str_paste);
            free(paste_line);

        } else {
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "(x:%ld, y:%ld): %d, %d, %d\n%s\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt,  nomin_hue,sat_out,chr_out);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "(<x:%ld, y:%ld>): %d, %d, %d\n%s\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt,  nomin_hue,sat_out,chr_out);
            } else {
                c1 = asprintf( & out_line, "(_x:%ld, y:%ld_): %d, %d, %d\n%s\nSaturation: %.1f\n    Chroma: %.1f", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt,  nomin_hue,sat_out,chr_out);
            }

            char str_out[c1+1];
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            DrawText(hdcWindow, str_out, -1, & xy_txt, DT_NOCLIP);
            free(out_line);
        }
    }

    if(redoCols==1){
        red2 = redInt;
        green2 = greenInt;
        blue2 = blueInt;
    }
        p_fixed2.x = p_fixed.x;
        p_fixed2.y = p_fixed.y;

    ReleaseDC(hwnd, hdcWindow);
    SelectObject(hdc_px_tmp, bmp_px_DIB_obj);
    DeleteObject(bmp_px_DIB_obj);
    DeleteObject(bmp_px_DIB);
    DeleteDC(hdc_px_tmp);
    DeleteObject(hBrush);
    ReleaseDC(NULL, hdc_px);

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

    if (GET_WHEEL_DELTA_WPARAM(wParam) > 0) {
        xy_txt.right += 1;
        xy_txt.bottom += 1;
    } else if (GET_WHEEL_DELTA_WPARAM(wParam) < 0) {
        long brx = (xy_txt.right > minWdt) ? brx - 1 : brx;
        long bry = (xy_txt.bottom > minHgt) ? bry - 1 : bry;
        xy_txt.right = brx;
        xy_txt.bottom = bry;
    }
    SetWindowPos(hwnd, HWND_TOP, 0, 0, xy_txt.right - xy_txt.left, xy_txt.bottom - xy_txt.top, SWP_NOMOVE);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {

    switch (message) {
    case WM_PAINT: {
        BeginPaint(hwnd, & ps);
        renderWnd(hwnd, ps);
        EndPaint(hwnd, & ps);
        return 0L;
    }
    break;
    case WM_MOUSEWHEEL:
        mousewheel_hdl(wParam);
        return 0L;
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hwnd, message, wParam, lParam);
    }

}

ATOM MyRegisterClass(HINSTANCE hInstance) {
    WNDCLASSEX wcex;
    wcex.cbSize = sizeof(WNDCLASSEX);
    wcex.style = CS_HREDRAW | CS_VREDRAW;
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
    return RegisterClassEx( & wcex);
}

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow) {

    RECT sz = xy_txt;
    /*{x-coordinate of the upper-left corner of the rectangle, y-coordinate of the upper-left corner of the rectangle,
    x-coordinate of the lower-right corner of the rectangle, y-coordinate of the lower-right corner of the rectangle}
    */
    AdjustWindowRect( & sz, WS_OVERLAPPEDWINDOW, TRUE);
    hwnd = CreateWindow("rgbClass", "Colour picker", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, xy_txt.right - xy_txt.left, xy_txt.bottom - xy_txt.top,
        NULL, NULL, hInstance, NULL);

    if (!hwnd) {
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


    if (IsWindowVisible(hwnd) == true) {
        SetWindowPos(
            hwnd,
            (HWND) HWND_TOPMOST,
            0, 0, 0, 0,
            SWP_NOMOVE | SWP_NOSIZE);
    }


    HHOOK hKeyboardHook;

    hKeyboardHook = SetWindowsHookEx(
        WH_KEYBOARD_LL,
        keyboardHookProc,
        hInstance,
        0);

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

    p_fixed.x=p.x;
    p_fixed.y=p.y;

    SetTimer(hwnd, 1, rfsh, NULL);

    MSG msg;
    while (GetMessage( & msg, NULL, 0, 0)) {
        TranslateMessage( & msg);
        DispatchMessage( & msg);
    }
    return (int) msg.wParam;
}
