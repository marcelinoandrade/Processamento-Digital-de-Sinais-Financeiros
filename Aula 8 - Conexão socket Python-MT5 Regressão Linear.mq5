//+--------------------------------------------------------------------------------+
//|                                                                           socket.mq5  |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                                            https://www.mql5.com |
//|                                                 Modified: Marcelino Andrade |
//+--------------------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//--- input parameters

sinput int          port                        =    9090;              //Porta de Comunicação TCP/IP
sinput string     addr                       =     "127.0.0.1";    //Endereço de Comunicação TCP/IP
sinput int          points_regression  =     100;               //Pontos da Regressão Linear
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //---
 //+------------------------------------------------------------------------------------------------+
//| Sequencia de troca de mensagens e desenho da reta de regressão      |
//+-------------------------------------------------------------------------------------------------+   
   
   int socket=SocketCreate();
   if(socket!=INVALID_HANDLE) 
      {
       if(SocketConnect(socket,addr,port,1000)) 
          {
            Print("Connected address:port ",addr,":",port);
            double clpr[];
            int copyed = CopyClose(_Symbol,PERIOD_CURRENT,0,points_regression,clpr);
            string tosend;
            for(int i=0;i<ArraySize(clpr);i++) tosend+=(string)clpr[i]+" ";       
            string received = socksend(socket, tosend) ? socketreceive(socket, points_regression) : "";   // Enviando preços ou recebendo pontos da regressão
            drawlr(received);        
          }
       else Print("Connection address:port ",addr,":",port," error ",GetLastError()); SocketClose(socket); 
      }
   else Print("Socket creation error ",GetLastError());   
}

//+--------------------------------------------------------------------------------+
//|  Metodo para enviar N últimos preços de fechamento      |
//+--------------------------------------------------------------------------------+ 
bool socksend(int sock,string request) 
  {
   char req[];
   int  len=StringToCharArray(request,req)-1;
   if(len<0) 
      return(false);
   return(SocketSend(sock,req,len)==len); 
  }
 
//+------------------------------------------------------------------+
//|  Metodo para receber os pontos da regressão      |
//+------------------------------------------------------------------+ 
string socketreceive(int sock,int timeout)
  {
   char rsp[];
   string result="";
   uint len;
   uint timeout_check=GetTickCount()+timeout;
   do
     {
      len=SocketIsReadable(sock);
      if(len)
        {
         int rsp_len;
         rsp_len=SocketRead(sock,rsp,len,timeout);
         if(rsp_len>0) 
           {
            result+=CharArrayToString(rsp,0,rsp_len); 
           }
        }
     }
   while((GetTickCount()<timeout_check) && !IsStopped());
   return result;
  }
//+------------------------------------------------------------------+
//|  Metodo para desenho da linha de regressão      |
//+------------------------------------------------------------------+  
  void drawlr(string points) 
  {
   string res[];
   StringSplit(points,' ',res);

   if(ArraySize(res)==2) 
     {
      Print("Price[0]: ",NormalizeDouble(StringToDouble(res[0]),4));
      Print("Price[1]: ",NormalizeDouble(StringToDouble(res[1]),4));
      datetime temp[];
      CopyTime(Symbol(),Period(),TimeCurrent(),points_regression,temp);
      ObjectCreate(0,                                                                                          // identificador gráfico
                            "regrline",                                                                              // nome objeto
                            OBJ_TREND,                                                                       // tipo objeto
                            0,                                                                                          // índice janela
                            TimeCurrent(),                                                                      // tempo do primeiro ponto de ancoragem
                            NormalizeDouble(StringToDouble(res[0]),_Digits),              // preço de N ponto de ancoragem
                            temp[0],                                                                                // tempo do trigésimo ponto de ancoragem
                            NormalizeDouble(StringToDouble(res[1]),_Digits));             // preço do trigésimo ponto de ancoragem
     }
  } 