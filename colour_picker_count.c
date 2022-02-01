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

long minHgt = 119;
long minWdt = 410;

u_int rfsh = 7;
u_int wdt= 1920;
u_int hgt = 1080;

HINSTANCE hInst;
HWND hwnd;

int shiftKy = 0;
int ctrlKy = 0;
int altKy = 0;
int F2Ky = 2;
int F2KyLast = 1;
int pastingNow = 0;

char * out_line = "";
char * paste_line = "";
char * nomin_hue = "Greyscale";

int redInt, greenInt, blueInt, red_mx, green_mx, blue_mx, grey, c0, c1;
int b_cnt=0;
int b_cnt_mx=0;
double red, green, blue, mx, sat_out, val_out, chr_out, mn, diff, hue_d, hue_out, actuWdt, actuHgt, pWdt, pHgt, mPos_x, mPos_y, w_ratio, h_ratio;

POINT p;
POINT p_fixed;
POINT p_fixed2;
BOOL b;
PAINTSTRUCT ps;
HDC hdc_px, hdc_px_tmp, hdcWindow, hdc_scr, hdc_scr_tmp;
BYTE* px_bit_ptr;
BYTE* scr_bit_ptr;
HBRUSH hBrush_white_m1 = CreateSolidBrush(RGB(0xFE,0xFE,0xFE));

DEVMODE dm;
RECT xy_txt = {0,0,minWdt,minHgt};
RECT xy_txt_bg = {0,0,minWdt-96,minHgt-39};
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
                F2KyLast = F2Ky;
                F2Ky = (F2Ky == 2) ? 0 : F2Ky + 1;
        }
        if (hooked_key -> vkCode == VK_F7) {
                b_cnt_mx=0;
                b_cnt=0;
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
    COLORREF txtCol=0x00010101; //1, 1, 1 so text pixels aren't counted
    COLORREF txtColBg=0x00FEFEFE; //254, 254, 254
    SetTextColor(hdcWindow,txtCol);
    SetBkColor(hdcWindow,txtColBg);

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
        hue_out=0;
        sat_out=0;
        chr_out=0;
        val_out=0;
    }
}
    F2KyLast = (F2Ky != F2KyLast) ? F2Ky : F2KyLast;

    if(redo==1){

        int Rd = red_mx;
        int Gr = green_mx;
        int Bl = blue_mx;

        double  mn = MIN(Rd, MIN(Gr, Bl));
        double  mx = MAX(Rd, MAX(Gr, Bl));
        double chr_raw=mx-mn;
        double chr=chr_raw/255;
          sat_out = (mx == 0) ? 0 : ((mx-mn) / mx) * 100;
          val_out = mx/2.55;
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
   }

        InvalidateRect(hwnd, nullptr, false);
        HBRUSH hBrush = CreateSolidBrush(RGB(redInt, greenInt, blueInt));
        FillRect(hdcWindow, & ps.rcPaint, hBrush);
        SetTextColor(hdcWindow,RGB(1,1,1));
        SetBkMode(hdcWindow,TRANSPARENT);
        FillRect(hdcWindow, &xy_txt_bg, hBrush_white_m1);

    //Add thousands separators:

    char* d_str="";
    int r=asprintf(&d_str,"%d",b_cnt_mx);
    char d_str_arr[r+1];
    strncpy(d_str_arr, d_str, r);
    d_str_arr[r] = '\0';

    int dg=(r>=4)?floor(r/3):0; //No of separators
    int len=(r%3==0)?r+dg:r+1+dg;
    char d_str_arr_sep[len];
    d_str_arr_sep[len-1]= '\0';

    if(r>=4){
        int tc=1;
        int ac=r-2;
        d_str_arr_sep[len-2]=d_str_arr[r-1];
        //printf("%d: %c\n",len-2,d_str_arr_sep[len-2]);
        for(int i=len-3; i>=0; i--){
            d_str_arr_sep[i]=(tc==3)?' ':d_str_arr[ac];
            ac=(tc==3)?ac:ac-1;
            tc=(tc==3)?0:tc+1;
           //printf("%d: %c\n",i,d_str_arr_sep[i]);
        }
    }else{ //no separators added
         strncpy(d_str_arr_sep, d_str, r);
         d_str_arr_sep[r] = '\0';
    }

    /* If b_cnt_mx could be negative:

        char d_str_arr_sep_out[((b_cnt_mx<0)?len+1:len)];
        d_str_arr_sep_out[((b_cnt_mx<0)?len:len-1)]='\0';
        if(b_cnt_mx<0){
            d_str_arr_sep_out[0]='-';
        }
        for(int i=0; i<((b_cnt_mx<0)?len+1:len); i++){
            d_str_arr_sep_out[((b_cnt_mx<0)?i+1:i)]= d_str_arr_sep[i];
        }
    */


    free(d_str);

    if(grey==0){
        if (shiftKy == 1) {
            c0 = asprintf( & paste_line, "%d, %d, %d", red_mx, green_mx, blue_mx);
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "PASTING (x:%ld, y:%ld): %d, %d, %d\n%s \(%.1f%c) - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, nomin_hue, hue_out,176,d_str_arr_sep, sat_out,val_out,chr_out);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "PASTING (<x:%ld, y:%ld>): %d, %d, %d\n%s \(%.1f%c) - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, nomin_hue, hue_out,176,d_str_arr_sep, sat_out,val_out,chr_out);
            } else {
                c1 = asprintf( & out_line, "PASTING (_x:%ld, y:%ld_): %d, %d, %d\n%s \(%.1f%c) - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f",p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, nomin_hue, hue_out,176,d_str_arr_sep, sat_out,val_out,chr_out);
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
                c1 = asprintf( & out_line, "(x:%ld, y:%ld): %d, %d, %d\n%s \(%.1f%c) - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, nomin_hue, hue_out,176,d_str_arr_sep, sat_out,val_out,chr_out);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "(<x:%ld, y:%ld>): %d, %d, %d\n%s \(%.1f%c) - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, nomin_hue, hue_out,176,d_str_arr_sep, sat_out,val_out,chr_out);
            } else {
                c1 = asprintf( & out_line, "(_x:%ld, y:%ld_): %d, %d, %d\n%s \(%.1f%c) - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx, nomin_hue, hue_out,176,d_str_arr_sep, sat_out,val_out,chr_out);
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
            c0 = asprintf( & paste_line, "%d, %d, %d", red_mx, green_mx, blue_mx);
            if (F2Ky == 1) {
                c1 = asprintf( & out_line, "PASTING (x:%ld, y:%ld): %d, %d, %d\n%s - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx,  nomin_hue,d_str_arr_sep,sat_out,val_out,chr_out);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "PASTING (<x:%ld, y:%ld>): %d, %d, %d\n%s - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx,  nomin_hue,d_str_arr_sep,sat_out,val_out,chr_out);
            } else {
                c1 = asprintf( & out_line, "PASTING (_x:%ld, y:%ld_): %d, %d, %d\n%s - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx,  nomin_hue,d_str_arr_sep,sat_out,val_out,chr_out);
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
                c1 = asprintf( & out_line, "(x:%ld, y:%ld): %d, %d, %d\n%s - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx,  nomin_hue,d_str_arr_sep,sat_out,val_out,chr_out);
            } else if (F2Ky == 2) {
                c1 = asprintf( & out_line, "(<x:%ld, y:%ld>): %d, %d, %d\n%s - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx,  nomin_hue,d_str_arr_sep,sat_out,val_out,chr_out);
            } else {
                c1 = asprintf( & out_line, "(_x:%ld, y:%ld_): %d, %d, %d\n%s - %s\n      Saturation: %.1f\n              Value: %.1f\nChroma: %.1f", p_fixed.x, p_fixed.y, red_mx, green_mx, blue_mx,  nomin_hue,d_str_arr_sep,sat_out,val_out,chr_out);
            }

            char str_out[c1+1];
            strncpy(str_out, out_line, c1);
            str_out[c1] = '\0';
            DrawText(hdcWindow, str_out, -1, & xy_txt, DT_NOCLIP);
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
