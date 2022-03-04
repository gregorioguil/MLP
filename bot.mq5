//+------------------------------------------------------------------+
//|                                                       Demo_I.mq5 |
//|                                     Copyright 2021, Lethan Corp. |
//|                           https://www.mql5.com/pt/users/14134597 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Lethan Corp."
#property link      "https://www.mql5.com/pt/users/14134597"
#property version   "1.00"

#include "ClientSocket.mqh"
#include <Trade\Trade.mqh>

input group   "General Configuration"
input string InpHost  = "localhost";
input int    InpPort  = 9091;
input int    InpSteps = 60;
input group   "General Expert"
input ulong  InpMagicEA = 999;
input double InpVol     = 0.01;
input int    InpTake    = 60;
input int    InpStop    = 60;


int      handle;
datetime m_last_time;
double   m_fast_ma[];

CClientSocket* Socket;
CTrade         m_trade;

double mim_vol, vol;
bool buy=false, sell=false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//---
   Socket=CClientSocket::Socket();
   Socket.Config(InpHost, InpPort);

   handle=iMA(Symbol(), Period(), 10, 0, MODE_EMA, PRICE_CLOSE);

   m_trade.SetExpertMagicNumber(InpMagicEA);

   SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN, mim_vol);

   if(InpVol<mim_vol)
     {
      vol=mim_vol;
     }
   else
     {
      vol=InpVol;
     }

   ArraySetAsSeries(m_fast_ma, true);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   CClientSocket::DeleteSocket();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(void)
  {
//---
   if(NewBar())
     {
      CheckPosition();
      
      if(buy||sell)
        return;
      
      if(!Socket.IsConnected())
         Print("Error : ", GetLastError(), " Line: ", __LINE__);

      string payload = "{'rates':[";
      for(int i=InpSteps; i>=0; i--)
        {
         if(i>=1)
            payload += string(iClose(Symbol(), Period(), i))+",";
         else
            payload += string(iClose(Symbol(), Period(), i))+"]}";
        }

      bool send = Socket.SocketSend(payload);
      if(send)
        {
         if(!Socket.IsConnected())
            Print("Error : ", GetLastError(), " Line: ", __LINE__);

         double yhat = StringToDouble(Socket.SocketReceive());

         Print("Value of Prediction: ", yhat);

         if(CopyBuffer(handle, 0, 0, 4, m_fast_ma)==-1)
            Print("Error in CopyBuffer");

         if(m_fast_ma[1]>m_fast_ma[2]&&m_fast_ma[2]>m_fast_ma[3])
           {
            if((iClose(Symbol(), Period(), 2)>iOpen(Symbol(), Period(), 2)&&iClose(Symbol(), Period(), 1)>iOpen(Symbol(), Period(), 1))&&yhat<0)
              {
               double price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               m_trade.Sell(vol, Symbol(), price, price*Point()+InpStop, price*Point()-InpTake);
              }
           }

         if(m_fast_ma[1]<m_fast_ma[2]&&m_fast_ma[2]<m_fast_ma[3])
           {
            if((iClose(Symbol(), Period(), 2)<iOpen(Symbol(), Period(), 2)&&iClose(Symbol(), Period(), 1)<iOpen(Symbol(), Period(), 1))&&yhat>0)
              {
               double price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
               m_trade.Buy(vol, Symbol(), price, price*Point()-InpStop, price*Point()+InpTake);
              }
           }
        }

      Socket.Close();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar(void)
  {
   datetime time[];
   if(CopyTime(Symbol(), Period(), 0, 1, time) < 1)
      return false;
   if(time[0] == m_last_time)
      return false;
   return bool(m_last_time = time[0]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckPosition(void)
  {
   buy = false;
   sell  = false;

   if(PositionSelect(Symbol()))
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY&&PositionGetInteger(POSITION_MAGIC) == InpMagicEA)
        {
         buy = true;
         sell  = false;
        }
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL&&PositionGetInteger(POSITION_MAGIC) == InpMagicEA)
        {
         sell = true;
         buy = false;
        }
     }
  }
//+------------------------------------------------------------------+
