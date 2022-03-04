import socket

class socketserver(object):
    def __init__(self, address, port):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.address = address
        self.port = port
        self.sock.bind((self.address, self.port))
        
    def socket_receive(self):
        self.sock.listen(1)
        self.conn, self.addr = self.sock.accept()
        self.cummdata = ''

        while True:
            data = self.conn.recv(10000)
            self.cummdata+=data.decode("utf-8")
            if not data:
                self.conn.close()
                break
            return self.cummdata
    
    def socket_send(self, message):
        self.sock.listen(1)
        self.conn, self.addr = self.sock.accept()
        self.conn.send(bytes(message, "utf-8"))
    
            
    def __del__(self):
        self.conn.close()