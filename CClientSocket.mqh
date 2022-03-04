class CClientSocket {
    private:
    static CClientSocket*  m_socket;
    int                    m_handler_socket;
    int                    m_port;
    string                 m_host;
    int                    m_time_out;
                        CClientSocket(void);
                        ~CClientSocket(void);
    public:
    static bool           DeleteSocket(void);
    bool                  SocketSend(string payload);
    string                SocketReceive(void);
    bool                  IsConnected(void);
    static CClientSocket *Socket(void);
    bool                  Config(string host, int port);
    bool                  Close(void);
};

static CClientSocket *CClientSocket::Socket(void) {
   if(CheckPointer(m_socket)==POINTER_INVALID)
      m_socket=new CClientSocket();
   return m_socket;
}

bool CClientSocket::IsConnected(void) {
   ResetLastError();
   bool res=true;

   m_handler_socket=SocketCreate();
   if(m_handler_socket==INVALID_HANDLE)
      res=false;

   if(!::SocketConnect(m_handler_socket,m_host,m_port,m_time_out))
      res=false;

   return res;
}

bool CClientSocket::Close(void) {
   bool res=false;
   if(SocketClose(m_handler_socket))
     {
      res=true;
      m_handler_socket=INVALID_HANDLE;
     }
   return res;
}