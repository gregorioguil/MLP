import ast
import pandas as pd
from model import Model
from server_socket import socketserver

host = 'localhost'
port = 9091 
n_steps = 60
TIMEFRAME = 24 | 0x4000
model   = Model(n_steps, "EURUSDm", TIMEFRAME)

if __name__ == "__main__":
    serv = socketserver(host, port)

    while True:
        print("<<--Waiting Prices to Predict-->>")
        rates = pd.DataFrame(ast.literal_eval(serv.socket_receive()))
        rates = rates.rates.pct_change(1)
        rates.dropna(inplace=True)
        rates = rates.values.reshape((1, n_steps))
        serv.socket_send(str(model.predict(rates).flatten()[0]))