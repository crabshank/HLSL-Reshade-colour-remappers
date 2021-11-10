#include <stdio.h>

#include <stdlib.h>

#include <windows.h>

#include <math.h>

#include <iostream>

#include <unistd.h>

#define MAX(x, y)(((x) > (y)) ? (x) : (y))
#define MIN(x, y)(((x) < (y)) ? (x) : (y))
#define minHgt 75
#define minWdt 410
#define _WIN32_WINNT 0x0400
#pragma comment(lib, "user32.lib")
int intCol[3] = {0,0,0};
HWND console = GetConsoleWindow();
HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);

void ClearConsoleToColors(HWND console, int rgbVal[3]) {

  RECT r;
  GetWindowRect(console, & r);

  CONSOLE_SCREEN_BUFFER_INFOEX info;
  info.cbSize = sizeof(info);

  GetConsoleScreenBufferInfoEx(hConsole, & info);

  info.ColorTable[0] = RGB(rgbVal[0], rgbVal[1], rgbVal[2]);

  SetConsoleScreenBufferInfoEx(hConsole, & info);

  MoveWindow(console, r.left, r.top, MAX(minWdt, r.right - r.left), MAX(minHgt, r.bottom - r.top), TRUE);

  return;
}

HHOOK hKeyboardHook;
int shiftKy = 0;
int ctrlKy = 0;
int F2Ky = 1;
int F2KyLast = 1;
int pastingNow = 0;

__declspec(dllexport) LRESULT CALLBACK KeyboardEvent(int nCode, WPARAM wParam, LPARAM lParam) {

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
      ClearConsoleToColors(console, intCol);
    }
    if (hooked_key -> vkCode == VK_LCONTROL || hooked_key -> vkCode == VK_RCONTROL || hooked_key -> vkCode == VK_CONTROL) {
      ctrlKy = 0;
    }
  }

  return CallNextHookEx(hKeyboardHook, nCode, wParam, lParam);
}

void MessageLoop() {
  MSG message;
  while (GetMessage( & message, NULL, 0, 0)) {
    TranslateMessage( & message);
    DispatchMessage( & message);
  }
}

DWORD WINAPI monitorKeys(LPVOID lpParm) {
  HINSTANCE hInstance = GetModuleHandle(NULL);
  if (!hInstance) hInstance = LoadLibrary((LPCSTR) lpParm);
  if (!hInstance) return 1;

  hKeyboardHook = SetWindowsHookEx(WH_KEYBOARD_LL, (HOOKPROC) KeyboardEvent, hInstance, NULL);
  MessageLoop();
  UnhookWindowsHookEx(hKeyboardHook);
  return 0;
}

void paster(HWND console, char * str_paste) {

  const size_t len = strlen(str_paste) + 1;
  HGLOBAL hGloblal = GlobalAlloc(GMEM_MOVEABLE, len);
  memcpy(GlobalLock(hGloblal), str_paste, len);
  GlobalUnlock(hGloblal);
  OpenClipboard(console);
  EmptyClipboard();
  SetClipboardData(CF_TEXT, hGloblal);
  CloseClipboard();
}

int main(int argc, char ** argv) {

  HANDLE hThread;
  DWORD dwThread;

  hThread = CreateThread(NULL, NULL, (LPTHREAD_START_ROUTINE) monitorKeys, (LPVOID) argv[0], NULL, & dwThread);

  HDC hDC = GetDC(NULL);
  POINT p;
  POINT p_fixed;
  POINT p_fixed2;
  BOOL b;
  b = GetCursorPos( & p);
  p_fixed.x = p.x;
  p_fixed.y = p.y;
  p_fixed2.x = p.x;
  p_fixed2.y = p.y;
  COLORREF color;
  int redInt, greenInt, blueInt, red2, green2, blue2, grey, out_col;
  double red, green, blue, mx, sat, mn, diff, hue_d;
  double hue_out = 0;
  char * nomin_hue = "Greyscale";
  char str_paste[MAX_PATH] = {0};

  RECT r;
  GetWindowRect(console, & r);
  MoveWindow(console, r.left, r.top, minWdt, minHgt, TRUE);

  while (1) {

    if ((ctrlKy == 1 && F2Ky == 1) || (F2Ky == 2)) {
      b = GetCursorPos( & p);
      p_fixed.x = p.x;
      p_fixed.y = p.y;
    }

    color = GetPixel(hDC, p.x, p.y);

    redInt = round(GetRValue(color));
    greenInt = round(GetGValue(color));
    blueInt = round(GetBValue(color));

    red = ((double) redInt) / 255.0;
    green = ((double) greenInt) / 255.0;
    blue = ((double) blueInt) / 255.0;


    if ( ((red2!=redInt)|| (green2!=greenInt) || (blue2!=blueInt)) || (shiftKy==1) || (F2Ky!=F2KyLast) || ( ( (ctrlKy==1 && F2Ky==1) || (F2Ky==2) ) && (p_fixed.x!=p_fixed2.x || p_fixed.y!=p_fixed2.y) ) ){
      F2KyLast = (F2Ky != F2KyLast) ? F2Ky : F2KyLast;
      system("cls");
      printf("                            ");
      intCol[0] = redInt;
      intCol[1] = greenInt;
      intCol[2] = blueInt;

      int Rd = redInt;
      int Gr = greenInt;
      int Bl = blueInt;

      mx = MAX(red, MAX(green, blue));
      sat = (mx == 0) ? 0 : ((mx - MIN(red, MIN(green, blue))) / mx) * 100;

      grey = ((Rd == Gr) && (Gr == Bl)) ? 1 : 0;
      mn = MIN(red, MIN(green, blue));
      diff = mx - mn;

      if (grey == 0) {

        if ((Rd > Gr) && (Rd > Bl)) {
          hue_d = (green - blue) / diff;
        } else if ((Gr > Rd) && (Gr > Bl)) {
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
        system("cls");
        ClearConsoleToColors(console, intCol);
        if (shiftKy == 1) {
          if (F2Ky == 1) {
            printf("\033[0;34;43mPASTING (x:%d, y:%d): %d, %d, %d\nSaturation: %.1f; %s \(%.1f deg) \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue, hue_out);
          } else if (F2Ky == 2) {
            printf("\033[0;34;43mPASTING (<x:%d, y:%d>): %d, %d, %d\nSaturation: %.1f; %s \(%.1f deg) \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue, hue_out);
          } else {
            printf("\033[0;34;43mPASTING (_x:%d, y:%d_): %d, %d, %d\nSaturation: %.1f; %s \(%.1f deg) \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue, hue_out);
          }
          _snprintf(str_paste, MAX_PATH - 1, "%d, %d, %d", redInt, greenInt, blueInt);
          pastingNow = (pastingNow == 0) ? 1 : pastingNow;
          paster(console, str_paste);
        } else {
          if (F2Ky == 1) {
            printf("\033[0;34;43m\(x:%d, y:%d): %d, %d, %d\nSaturation: %.1f; %s \(%.1f deg) \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue, hue_out);
          } else if (F2Ky == 2) {
            printf("\033[0;34;43m\(<x:%d, y:%d>): %d, %d, %d\nSaturation: %.1f; %s \(%.1f deg) \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue, hue_out);
          } else {
            printf("\033[0;34;43m\(_x:%d, y:%d_): %d, %d, %d\nSaturation: %.1f; %s \(%.1f deg) \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue, hue_out);
          }
        }
      } else {
        system("cls");
        ClearConsoleToColors(console, intCol);
        nomin_hue = "Greyscale";
        if (shiftKy == 1) {
          if (F2Ky == 1) {
            printf("\033[0;34;43mPASTING (x:%d, y:%d): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue);
          } else if (F2Ky == 2) {
            printf("\033[0;34;43mPASTING (<x:%d, y:%d>): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue);
          } else {
            printf("\033[0;34;43mPASTING (_x:%d, y:%d_): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue);
          }

          _snprintf(str_paste, MAX_PATH - 1, "%d, %d, %d", redInt, greenInt, blueInt);
          pastingNow = (pastingNow == 0) ? 1 : pastingNow;
          paster(console, str_paste);
        } else {
          if (F2Ky == 1) {
            printf("\033[0;34;43m\(x:%d, y:%d): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue);
          } else if (F2Ky == 2) {
            printf("\033[0;34;43m\(<x:%d, y:%d>): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue);
          } else {
            printf("\033[0;34;43m\(_x:%d, y:%d_): %d, %d, %d\nSaturation: %.1f; %s \033[0m", p_fixed.x, p_fixed.y, redInt, greenInt, blueInt, sat, nomin_hue);
          }

        }
      }

      red2 = redInt;
      green2 = greenInt;
      blue2 = blueInt;
      p_fixed2.x = p_fixed.x;
      p_fixed2.y = p_fixed.y;

    }

    sleep(1 / 144);

  }

  if (hThread) return WaitForSingleObject(hThread, INFINITE);
  else return 1;

}
