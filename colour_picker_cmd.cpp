#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <math.h>
#include <iostream>
#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))
#define minHgt 75
#define minWdt 410

void paster(HWND console,char* str_paste){

           const size_t len = strlen(str_paste) + 1;
    HGLOBAL hGloblal =  GlobalAlloc(GMEM_MOVEABLE, len);
    memcpy(GlobalLock(hGloblal),str_paste , len);
    GlobalUnlock(hGloblal);
    OpenClipboard(console);
    EmptyClipboard();
    SetClipboardData(CF_TEXT, hGloblal);
    CloseClipboard();
}

void ClearConsoleToColors(HWND console,int rgbVal[3])
{

    RECT r;
    GetWindowRect(console, &r);
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);

    CONSOLE_SCREEN_BUFFER_INFOEX info;
    info.cbSize = sizeof(info);

   GetConsoleScreenBufferInfoEx(hConsole, &info);

info.ColorTable[0] = RGB(rgbVal[0],rgbVal[1],rgbVal[2]);

SetConsoleScreenBufferInfoEx(hConsole, &info);


    MoveWindow(console, r.left, r.top, MAX(minWdt,r.right-r.left), MAX(minHgt,r.bottom-r.top), TRUE);

     return;
}

int main()
{


HDC hDC = GetDC(NULL);
POINT p;
POINT p_fixed;
POINT p_fixed2;
BOOL b;
                  b= GetCursorPos(&p);
                  p_fixed.x=p.x;
                  p_fixed.y=p.y;
                p_fixed2.x=p.x;
                  p_fixed2.y=p.y;
COLORREF color;
int redInt,greenInt,blueInt,red2,green2,blue2,grey,out_col;
double red,green,blue,mx,sat,mn,diff,hue_d;
double hue_out=0;
char* nomin_hue="Greyscale";
char str_paste[MAX_PATH]={0};
    HANDLE rhnd = GetStdHandle(STD_INPUT_HANDLE);

    DWORD Events = 0;
    DWORD EventsRead = 0;
int shiftKy=0;
int altKy=0;
int ctrlKy=0;

 HWND console = GetConsoleWindow();

     RECT r;
    GetWindowRect(console, &r);
MoveWindow(console, r.left, r.top, minWdt,minHgt, TRUE);

while(1){

 GetNumberOfConsoleInputEvents(rhnd, &Events);

        if(Events != 0){

            INPUT_RECORD eventBuffer[Events];

            ReadConsoleInput(rhnd, eventBuffer, Events, &EventsRead);

            for(DWORD i = 0; i < EventsRead; ++i){

                if(eventBuffer[i].EventType == KEY_EVENT){
                        if(eventBuffer[i].Event.KeyEvent.bKeyDown){

                    if(eventBuffer[i].Event.KeyEvent.wVirtualKeyCode==VK_SHIFT){
                            shiftKy=1;
                          // break;
                    }
                    if(eventBuffer[i].Event.KeyEvent.wVirtualKeyCode==VK_CONTROL){
                            ctrlKy=1;
                          // break;
                    }
                    /*if(eventBuffer[i].Event.KeyEvent.wVirtualKeyCode==VK_MENU){
                            altKy=1;
                          // break;
                    }*/
                }else{
                     if(eventBuffer[i].Event.KeyEvent.wVirtualKeyCode==VK_SHIFT){
                        shiftKy=2;
                        break;
                     }
                    if(eventBuffer[i].Event.KeyEvent.wVirtualKeyCode==VK_CONTROL){
                        ctrlKy=2;
                        break;
                    }
                   /* if(eventBuffer[i].Event.KeyEvent.wVirtualKeyCode==VK_MENU){
                        altKy=2;
                        break;
                    }*/
                }

            }
        }

        }
          if(ctrlKy==1){
                  b= GetCursorPos(&p);
                  p_fixed.x=p.x;
                  p_fixed.y=p.y;
               }

          color = GetPixel(hDC, p.x, p.y);

redInt= round(GetRValue(color));
greenInt= round(GetGValue(color));
blueInt= round(GetBValue(color));

red= ((double)redInt)/255.0;
green= ((double)greenInt)/255.0;
blue= ((double)blueInt)/255.0;


if ((((red2!=redInt)|| (green2!=greenInt) || (blue2!=blueInt)))||((shiftKy==1)||(shiftKy==2))||(ctrlKy==1&&(p_fixed2.x!=p_fixed.x || p_fixed2.y!=p_fixed.y))){

               system("cls");
 printf("                            ");
 int intCol[3]={redInt,greenInt,blueInt};
                if ((redInt==0)&&(greenInt==0)&&(blueInt==0)){
                         system("cls");
               ClearConsoleToColors(console,intCol);
               nomin_hue="Greyscale";
                  if(shiftKy==1){
        printf("\033[0;34;43mPASTING \(x:%d,y:%d): %d, %d, %d\nSaturation: 0.0; %s \033[0m",p_fixed.x,p_fixed.y,redInt,greenInt,blueInt,nomin_hue);
        _snprintf(str_paste, MAX_PATH-1,"%d, %d, %d",redInt,greenInt,blueInt);
        paster(console,str_paste);

        }else{
            printf("\033[0;34;43m\(x:%d,y:%d): %d, %d, %d\nSaturation: 0.0; %s \033[0m",p_fixed.x,p_fixed.y,redInt,greenInt,blueInt,nomin_hue);
  }

                }else{
int Rd=redInt;
int Gr=greenInt;
int Bl=blueInt;

mx=MAX(red,MAX(green,blue));
sat=((mx-MIN(red,MIN(green,blue)))/mx)*100;

grey=((Rd==Gr)&&(Gr==Bl))?1:0;
  mn=MIN(red,MIN(green,blue));
  diff=mx-mn;

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
    }
     system("cls");
               ClearConsoleToColors(console,intCol);
                       if(shiftKy==1){
  printf("\033[0;34;43mPASTING \(x:%d,y:%d): %d, %d, %d\nSaturation: %.1f; %s \(%.1f deg) \033[0m",p_fixed.x,p_fixed.y,redInt,greenInt,blueInt,sat,nomin_hue,hue_out);
          _snprintf(str_paste, MAX_PATH-1,"%d, %d, %d",redInt,greenInt,blueInt);
        paster(console,str_paste);
                   }else{
           printf("\033[0;34;43m\(x:%d,y:%d): %d, %d, %d\nSaturation: %.1f; %s \(%.1f deg) \033[0m",p_fixed.x,p_fixed.y,redInt,greenInt,blueInt,sat,nomin_hue,hue_out);

    }
}else{
     system("cls");
               ClearConsoleToColors(console,intCol);
                   nomin_hue="Greyscale";
                       if(shiftKy==1){
  printf("\033[0;34;43mPASTING \(x:%d,y:%d): %d, %d, %d\nSaturation: %.1f; %s \033[0m",p_fixed.x,p_fixed.y,redInt,greenInt,blueInt,sat,nomin_hue);
          _snprintf(str_paste, MAX_PATH-1,"%d, %d, %d",redInt,greenInt,blueInt);
        paster(console,str_paste);
                   }else{
           printf("\033[0;34;43m\(x:%d,y:%d): %d, %d, %d\nSaturation: %.1f; %s \033[0m",p_fixed.x,p_fixed.y,redInt,greenInt,blueInt,sat,nomin_hue);

    }
}

shiftKy=0;
altKy=0;
ctrlKy=0;
                }


red2=redInt;
green2=greenInt;
blue2=blueInt;
p_fixed2.x=p_fixed.x;
p_fixed2.y=p_fixed.y;

 }

}

  return 0;
}
