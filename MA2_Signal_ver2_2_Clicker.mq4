//+---------------------------------------------------------------------------------+
//+ MA2_Signal                                                                      +
//+ Индикатор сигналов при пересечении 2-х средних                                  +
//+                                                                                 +
//+ Внешние параметры:                                                              +
//+  ExtPeriodFastMA - период быстой средней                                        +
//+  ExtPeriodSlowMA - период медленной средней                                     +
//+  ExtModeFastMA   - режим быстой средней                                         +
//+  ExtModeSlowMA   - режим медленной средней                                      +
//+   Режимы: 0 = SMA, 1 = EMA, 2 = SMMA (сглаженная), 3 = LWMA (взвешенная)        +
//+  ExtPriceFastMA  - цена быстой средней                                          +
//+  ExtPriceSlowMA  - цена медленной средней                                       +
//+   Цены: 0 = Close, 1 = Open, 2 = High, 3 = Low, 4 = HL/2, 5 = HLC/3, 6 = HLCC/4 +
//+---------------------------------------------------------------------------------+
#property copyright "Copyright © 2018, Asphodel"
#property link      "https://trdrobot.com/"

//---- Определение индикаторов
#property indicator_chart_window
#property indicator_buffers 4
//---- Цвета
#property indicator_color1 Magenta // 5
#property indicator_color2 Blue        // 7
#property indicator_color3 MediumBlue
#property indicator_color4 Tomato
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 1
#property indicator_width4 1


//--- External libraries
#import "user32.dll"
bool     SetCursorPos(int X_coord_mouse, int Y_coord_mouse);
void     mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
#import

//Mouse constants
const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
const uint MOUSEEVENTF_LEFTUP = 0x0004;

//---- Параметры
extern int    ExtPeriodFastMA = 5;
extern int    ExtPeriodSlowMA = 7;
extern int    ExtModeFastMA   = 1; // 0 = SMA, 1 = EMA, 2 = SMMA, 3 = LWMA
extern int    ExtModeSlowMA   = 1; // 0 = SMA, 1 = EMA, 2 = SMMA, 3 = LWMA
extern int    ExtPriceFastMA  = 0; // 0 = Close, 1 = Open, 2 = High, 3 = Low, 4 = HL/2, 5 = HLC/3, 6 = HLCC/4
extern int    ExtPriceSlowMA  = 1; // 0 = Close, 1 = Open, 2 = High, 3 = Low, 4 = HL/2, 5 = HLC/3, 6 = HLCC/4
extern bool   EnableAlert     = true;
//extern bool   EnableSound     = true;
//extern string ExtSoundFileNameUp = "Покупаем.wav";
//extern string ExtSoundFileNameDn = "Продаем.wav";
extern int   BuyButton_X=100;   //X_coords of buy button
extern int   BuyButton_Y=100;   //Y_coords of buy button
extern int   SellButton_X=1200;  //X_coords of sell button
extern int   SellButton_Y=100;  //Y_coords of sell button

//---- Буферы
double FastMA[];
double SlowMA[];
double CrossUp[];
double CrossDown[];
static int bBuy  = 0;
static int bSell = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- Установка параметров прорисовки
//     Средние
   SetIndexStyle(0, DRAW_LINE);
   SetIndexStyle(1, DRAW_LINE);
//     Сигналы
   SetIndexStyle(2, DRAW_ARROW, EMPTY);
   SetIndexArrow(2, 233);
   SetIndexStyle(3, DRAW_ARROW, EMPTY);
   SetIndexArrow(3, 234);

//---- Задание буферов
   SetIndexBuffer(0, FastMA);
   SetIndexBuffer(1, SlowMA);
   SetIndexBuffer(2, CrossUp);
   SetIndexBuffer(3, CrossDown);

   IndicatorDigits(MarketInfo(Symbol(), MODE_DIGITS));

//---- Название и метки
   IndicatorShortName("MA2_SignalV2(" + ExtPeriodFastMA + "," + ExtPeriodSlowMA);
   SetIndexLabel(0, "MA("+ ExtPeriodFastMA + "," + ExtPeriodSlowMA+")" + ExtPeriodFastMA);
   SetIndexLabel(1, "MA(" + ExtPeriodFastMA + "," + ExtPeriodSlowMA+")" + ExtPeriodSlowMA);
   SetIndexLabel(2, "Buy");
   SetIndexLabel(3, "Sell");

   return (0);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   bool   bConditionUp;
   bool   bConditionDown;
   double Range;
   double AvgRange;
   int    iLimit;
   int    i;
   int    counter;
   int    counted_bars = IndicatorCounted();

//---- check for possible errors
   if(counted_bars < 0)
      return (-1);

//---- last counted bar will be recounted
   if(counted_bars > 0)
      counted_bars--;

   iLimit = Bars - counted_bars;

   for(i = iLimit; i >=0; i--)
     {
      FastMA[i] = iMA(NULL, 0, ExtPeriodFastMA, 0, ExtModeFastMA, ExtPriceFastMA, i);
      SlowMA[i] = iMA(NULL, 0, ExtPeriodSlowMA, 0, ExtModeSlowMA, ExtPriceSlowMA, i);
      AvgRange = 0;
      bConditionUp = 0;
      bConditionDown = 0;
      for(counter = i; counter <= i + 9; counter++)
        {
         AvgRange += MathAbs(High[ counter ] - Low[ counter ]);
        }
      Range = AvgRange/10;
      bConditionUp   = (FastMA[i+1] >= SlowMA[i+1]) &&
                       (FastMA[i+2] <= SlowMA[i+2]) &&
                       (FastMA[i] > SlowMA[i]);   // пересечение вверх
      bConditionDown = (FastMA[i+1] <= SlowMA[i+1]) &&
                       (FastMA[i+2] >= SlowMA[i+2]) &&
                       (FastMA[i] < SlowMA[i]);   // пересечение вниз
      if(bConditionUp)    //
        {
         CrossUp[i+1] = SlowMA[i+1]-Range * 0.75;
         CrossDown[i+1] = EMPTY_VALUE;
         bConditionDown = false;
        }

      if(bConditionDown)    //
        {
         CrossDown[i+1] = SlowMA[i+1]+Range * 0.75;
         CrossUp[i+1] = EMPTY_VALUE;
         bConditionUp = false;
        }

      if(!bConditionUp && !bConditionDown)
        {
         CrossDown[i+1] = EMPTY_VALUE;
         CrossUp[i+1] = EMPTY_VALUE;
        }

      if(bConditionUp && !bBuy==1 && i==0)
        {
         bBuy  = 1;  // установка флага покупки
         bSell = 0; // сброс флага продажи

         SetCursorPos(BuyButton_X, BuyButton_Y);
         mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
         Sleep(1);
         mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);

         if(EnableAlert)
            Alert(Symbol()," ",Period(),"M  Achtung BUY ");  // звуковой сигнал
         //      if(EnableSound) PlaySound( ExtSoundFileNameUp );
        }
      if(bConditionDown && !bSell==1 && i==0)
        {
         bBuy  = 0;  // установка флага покупки
         bSell = 1; // сброс флага продажи

         SetCursorPos(SellButton_X, SellButton_Y);
         mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
         Sleep(1);
         mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);

         if(EnableAlert)
            Alert(Symbol()," ",Period(),"M   Achtung SELL ");  // звуковой сигнал
         //      if(EnableSound) PlaySound( ExtSoundFileNameDn );
        }
     }
   return (0);
  }
//+------------------------------------------------------------------+
