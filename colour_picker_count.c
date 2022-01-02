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

long minHgt = 75;
long minWdt = 410;

u_int rfsh = 7;
u_int wdt= 1920;
u_int hgt = 1080;

HINSTANCE hInst;
HWND hwnd;

int shiftKy = 0;
int ctrlKy = 0;
int altKy = 0;
int F2Ky = 1;
int F2KyLast = 1;
int pastingNow = 0;

char * out_line = "";
char * paste_line = "";
char * nomin_hue = "Greyscale";

int redInt, greenInt, blueInt, red_mx, green_mx, blue_mx, grey, out_col, c0, c1;
int b_cnt=0;
int b_cnt_mx=0;
double red, green, blue, mx, sat, mn, diff, hue_d, hue_out;
COLORREF color;
POINT p;
POINT p_fixed;
POINT p_fixed2;
BOOL b;
PAINTSTRUCT ps;
HDC hdc_px, hdc_px_tmp, hdcWindow, hdc_scr, hdc_scr_tmp;
BYTE* px_bit_ptr;
BYTE* scr_bit_ptr;

DEVMODE dm = {0};
RECT xy_txt = {0,0,minWdt,minHgt};
/*{x-coordinate of the upper-left corner of the rectangle, y-coordinate of the upper-left corner of the rectangle,
  x-coordinate of the lower-right corner of the rectangle, y-coordinate of the lower-right corner of the rectangle}
  */

LRESULT CALLBACK keyboardHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
    PKBDLLHOOKSTRUCT hooked_key = (PKBDLLHOOKSTRUCT) lParam;

    if ((wParam == WM_SYSKEYDOWN) || (wParam == WM_KEYDOWN)) {
        if (hooked_key -> vkCode == VK_LMENU || hooked_key -> vkCode == VK_RMENU || hooked_key -> vkCode == VK_MENU){
            altKy = 1;
        }
        if (hooked_key -> vkCode == VK_LSHIFT || hooked_key -> vkCode == VK_RSHIFT || hooked_key -> vkCode == VK_SHIFT) {
            shiftKy = 1;
        }
        if (hooked_key -> vkCode == VK_LCONTROL || hooked_key -> vkCode == VK_RCONTROL || hooked_key -> vkCode == VK_CONTROL) {
            ctrlKy = 1;
        }
        if (hooked_key -> vkCode == VK_F2) {
            if(altKy==0){
                F2KyLast = F2Ky;
                F2Ky = (F2Ky == 2) ? 0 : F2Ky + 1;
            }else{
                b_cnt_mx=0;
                b_cnt=0;
            }
        }

    } else if ((wParam == WM_SYSKEYUP) || (wParam == WM_KEYUP)) {
        if (hooked_key -> vkCode == VK_LMENU || hooked_key -> vkCode == VK_RMENU || hooked_key -> vkCode == VK_MENU){
            altKy = 0;
        }
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

void get_RGB_at_x_y(const BYTE* bit_ptr, int x, int y, int RGB[3], int b_wdt){
    int index=4*(y*b_wdt+x);

    RGB[2]=(int)bit_ptr[index];
    RGB[1]=(int)bit_ptr[index+1];
    RGB[0]=(int)bit_ptr[index+2];

}

void renderWnd(HWND hwnd, PAINTSTRUCT ps) {

    if ((ctrlKy == 1 && F2Ky == 1) || (F2Ky == 2)) {
        b = GetCursorPos( & p);
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
	bmp_px.bmiHeader.biHeight = -1; //negative so (0,0) is at top left
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


    hdc_scr = GetDC(NULL);
    hdc_scr_tmp = CreateCompatibleDC(NULL);

   int redo = ((F2Ky != F2KyLast) || (((ctrlKy == 1 && F2Ky == 1) || (F2Ky == 2)) && (p_fixed.x != p_fixed2.x || p_fixed.y != p_fixed2.y))) ? 1 : 0;
   if(redo==1){
    b_cnt=0;
    b_cnt_mx=0;
   }
    b_cnt=b_cnt_mx;
    HBITMAP bmp_scr_DIB;
    HGDIOBJ bmp_scr_DIB_obj;
    BITMAPINFO bmp_scr;
    if(altKy==0){
   if(((redInt!=0 || greenInt!=0 || blueInt!=0)||redo==1)){//check for new max
        ZeroMemory(&bmp_scr, sizeof(BITMAPINFO));
        bmp_scr.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
        bmp_scr.bmiHeader.biWidth = wdt;
        bmp_scr.bmiHeader.biHeight = -hgt;  //negative so (0,0) is at top left
        bmp_scr.bmiHeader.biPlanes = 1;
        bmp_scr.bmiHeader.biBitCount = 32;

        bmp_scr_DIB=CreateDIBSection(hdc_scr_tmp,&bmp_scr,DIB_RGB_COLORS,(void**)(&scr_bit_ptr),NULL,NULL);
        bmp_scr_DIB_obj=SelectObject(hdc_scr_tmp,bmp_scr_DIB);
        BitBlt(hdc_scr_tmp, 0, 0, wdt, hgt, hdc_scr, 0,0, SRCCOPY);
        b_cnt=0;
        for(int x=0; x<wdt; x++){
        for(int y=0; y<hgt; y++){
            int currRGB[3];
            get_RGB_at_x_y(scr_bit_ptr,x,y,currRGB,wdt);
            b_cnt=(currRGB[0]==0 && currRGB[1]==0 && currRGB[2]==0)?b_cnt+1:b_cnt;
        }
        }

        if(b_cnt>=b_cnt_mx || redo==1){
            b_cnt_mx=b_cnt;
                red_mx=redInt;
                green_mx=greenInt;
                blue_mx=blueInt;
                grey = ((red_mx == green_mx) && (green_mx == blue_mx)) ? 1 : 0;
                redo=1;
        }
    }else if(red_mx==0 && green_mx==0 && blue_mx==0){
        grey=1;
        nomin_hue = "Greyscale";
        out_col=0;
        hue_out=0;
        sat=0;
    }
}
    F2KyLast = (F2Ky != F2KyLast) ? F2Ky : F2KyLast;

    if(redo==1){

        int Rd = red_mx;
        int Gr = green_mx;
        int Bl = blue_mx;

        mx = MAX(red, MAX(green, blue));
        sat = (mx == 0) ? 0 : ((mx - MIN(red, MIN(green, blue))) / mx) * 100;

        grey = ((Rd == Gr) && (Gr == Bl)) ? 1 : 0;
        mn = MIN(red, MIN(green, blue));
        diff = mx - mn;
        nomin_hue = "Greyscale";
        out_col=0;
        hue_out=0;
        if (grey == 0) {

            if ((Rd >= Gr) && (Rd >= Bl)) {
                hue_d = (green - blue) / diff;
            } else if ((Gr >= Rd) && (Gr >= Bl)) {
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
   }

        InvalidateRect(hwnd, nullptr, false);
        HBRUSH hBrush = CreateSolidBrush(RGB(red_mx, green_mx, blue_mx));
        FillRect(hdcWindow, & ps.rcPaint, hBrush);

    if(grey==0){
        if (shiftKy == 1) {
            c0 = asprintf( & paste_line, "%d, %d, %d", red_mx, green_mx, blue_mx);
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "PASTING (x:%ld, y:%ld): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c) - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176,b_cnt_mx);
                //printf("\033[0;34;43mPASTING (x:%ld, y:%ld): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "PASTING (<x:%ld, y:%ld>): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c) - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176,b_cnt_mx);
                //printf("\033[0;34;43mPASTING (<x:%ld, y:%ld>): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176);
            } else {
                c1 = asprintf( & out_line, "PASTING (_x:%ld, y:%ld_): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c) - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176,b_cnt_mx);
                //printf("\033[0;34;43mPASTING (_x:%ld, y:%ld_): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176);
            }

            char* str_out=(char*)malloc((c1+1)*sizeof(char));
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            DrawText(hdcWindow, str_out, -1, & xy_txt, DT_NOCLIP);
            free(str_out);
            free(out_line);

            char* str_paste=(char*)malloc((c0+1)*sizeof(char));
            strncpy(str_paste, paste_line, c0);
            str_paste[c0] = '\0';
            pastingNow = (pastingNow == 0) ? 1 : pastingNow;
            paster(hwnd, str_paste);
            free(str_paste);
            free(paste_line);

        } else {
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "(x:%ld, y:%ld): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c) - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176,b_cnt_mx);
                //printf("\033[0;34;43m\(x:%ld, y:%ld): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "(<x:%ld, y:%ld>): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c) - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176,b_cnt_mx);
                //printf("\033[0;34;43m\(<x:%ld, y:%ld>): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176);
            } else {
                c1 = asprintf( & out_line, "(_x:%ld, y:%ld_): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c) - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176,b_cnt_mx);
                //printf("\033[0;34;43m\(_x:%ld, y:%ld_): %d, %d, %d\nSaturation: %.1f; %s \(%.1f%c \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, hue_out,176);
            }

            char* str_out=(char*)malloc((c1+1)*sizeof(char));
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            DrawText(hdcWindow, str_out, -1, & xy_txt, DT_NOCLIP);
            free(str_out);
            free(out_line);
        }


    }else{
         //if grey:

        if (shiftKy == 1) {
            c0 = asprintf( & paste_line, "%d, %d, %d", red_mx, green_mx, blue_mx);
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "PASTING (x:%ld, y:%ld): %d, %d, %d\nSaturation: %.1f; %s - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue,b_cnt_mx);
                //printf("\033[0;34;43mPASTING (x:%ld, y:%ld): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "PASTING (<x:%ld, y:%ld>): %d, %d, %d\nSaturation: %.1f; %s - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue,b_cnt_mx);
                // printf("\033[0;34;43mPASTING (<x:%ld, y:%ld>): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue);
            } else {
                c1 = asprintf( & out_line, "PASTING (_x:%ld, y:%ld_): %d, %d, %d\nSaturation: %.1f; %s - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue,b_cnt_mx);
                // printf("\033[0;34;43mPASTING (_x:%ld, y:%ld_): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue);
            }

            char* str_out=(char*)malloc((c1+1)*sizeof(char));
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            DrawText(hdcWindow, str_out, -1, & xy_txt, DT_NOCLIP);
            free(str_out);
            free(out_line);

            char* str_paste=(char*)malloc((c0+1)*sizeof(char));
            strncpy(str_paste, paste_line, c0);
            str_paste[c0] = '\0';
            pastingNow = (pastingNow == 0) ? 1 : pastingNow;
            paster(hwnd, str_paste);
            free(str_paste);
            free(paste_line);

        } else {
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "(x:%ld, y:%ld): %d, %d, %d\nSaturation: %.1f; %s - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, b_cnt_mx);
                //printf("\033[0;34;43m\(x:%ld, y:%ld): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "(<x:%ld, y:%ld>): %d, %d, %d\nSaturation: %.1f; %s - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, b_cnt_mx);
                // printf("\033[0;34;43m\(<x:%ld, y:%ld>): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue);
            } else {
                c1 = asprintf( & out_line, "(_x:%ld, y:%ld_): %d, %d, %d\nSaturation: %.1f; %s - %d", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue, b_cnt_mx);
                //  printf("\033[0;34;43m\(_x:%ld, y:%ld_): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, sat, nomin_hue);
            }

            char* str_out=(char*)malloc((c1+1)*sizeof(char));
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            DrawText(hdcWindow, str_out, -1, & xy_txt, DT_NOCLIP);
            free(str_out);
            free(out_line);
        }
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
    SelectObject(hdc_scr_tmp, bmp_scr_DIB_obj);
    DeleteObject(bmp_scr_DIB_obj);
    DeleteObject(bmp_scr_DIB);
    DeleteDC(hdc_scr_tmp);
    ReleaseDC(NULL, hdc_scr);

}

void mousewheel_hdl(WPARAM wParam) {
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
    hwnd = CreateWindow("rgbClass", "Colour picker - count black pixels", WS_OVERLAPPEDWINDOW,
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

    b = GetCursorPos( & p);
    p_fixed.x = p.x;
    p_fixed.y = p.y;

    HHOOK hKeyboardHook;

    hKeyboardHook = SetWindowsHookEx(
        WH_KEYBOARD_LL,
        keyboardHookProc,
        hInstance,
        0);

    dm = {0};
    dm.dmSize = sizeof(DEVMODE);
    if (EnumDisplaySettings(NULL, ENUM_CURRENT_SETTINGS, & dm)) {
        rfsh = round(1000 * ((double)(dm.dmDisplayFrequency)));
    }

    SetTimer(hwnd, 1, rfsh, NULL);

    MSG msg;
    while (GetMessage( & msg, NULL, 0, 0)) {
        TranslateMessage( & msg);
        DispatchMessage( & msg);
    }
    return (int) msg.wParam;
}