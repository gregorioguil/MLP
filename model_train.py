import MetaTrader5 as mt5
import numpy as np
from pandas import to_datetime, DataFrame
from datetime import datetime, timezone
from matplotlib import pyplot
from sklearn.metrics import mean_squared_error
from math import sqrt

from tensorflow.keras import Sequential
from tensorflow.keras.layers import Dense
from tensorflow.keras.callbacks import *


symbol = "EURUSDm"
date_ini = datetime(2020, 1, 1, tzinfo=timezone.utc)
date_end = datetime(2021, 7, 1, tzinfo=timezone.utc)
period   = mt5.TIMEFRAME_D1

def train_test_split(values, fator):
    train_size = int(len(values) * fator)
    return np.array(values[0:train_size]), np.array(values[train_size:len(values)])

# split a univariate sequence into samples
def split_sequence(sequence, n_steps):
        X, y = list(), list()
        for i in range(len(sequence)):
                end_ix = i + n_steps
                if end_ix > len(sequence)-1:
                        break
                seq_x, seq_y = sequence[i:end_ix], sequence[end_ix]
                X.append(seq_x)
                y.append(seq_y)
        return np.array(X), np.array(y)

if not mt5.initialize():
    print("initialize() failed")
    mt5.shutdown()
    raise Exception("Error Getting Data")

rates = mt5.copy_rates_range(symbol, period, date_ini, date_end)
mt5.shutdown()
rates = DataFrame(rates)

if rates.empty:
    raise Exception("Error Getting Data")

rates['time'] = to_datetime(rates['time'], unit='s')
rates.set_index(['time'], inplace=True)

rates = rates.close.pct_change(1)
rates = rates.dropna()

X, y = train_test_split(rates, 0.70)
X = X.reshape(X.shape[0])
y = y.reshape(y.shape[0])

train, test = train_test_split(X, 0.7)

n_steps = 60
verbose = 1
epochs  = 50

X_train, y_train = split_sequence(train, n_steps)
X_test, y_test   = split_sequence(test, n_steps)
X_val, y_val     = split_sequence(y, n_steps)

# define model
model = Sequential()
model.add(Dense(200, activation='relu', input_dim=n_steps))
model.add(Dense(1))
model.compile(optimizer='adam', loss='mse')

history = model.fit(X_train
                   ,y_train  
                   ,epochs=epochs
                   ,verbose=verbose
                   ,validation_data=(X_test, y_test))

model.save(r'C:\Users\Micro\Documents\MLP\model_train_'+symbol+'.h5')

pyplot.title('Loss')
pyplot.plot(history.history['loss'], label='train')
pyplot.plot(history.history['val_loss'], label='test')
pyplot.legend()
pyplot.show()

history = list()
yhat    = list()

for i in range(0, len(X_val)):
        pred = X_val[i]
        pred = pred.reshape((1, n_steps))
        history.append(y_val[i])
        yhat.append(model.predict(pred).flatten()[0])

pyplot.figure(figsize=(10, 5))
pyplot.plot(history,"*")
pyplot.plot(yhat,"+")
pyplot.plot(history, label='real')
pyplot.plot(yhat, label='prediction')
pyplot.ylabel('Price Close', size=10)
pyplot.xlabel('time', size=10)
pyplot.legend(fontsize=10)

pyplot.show()
rmse = sqrt(mean_squared_error(history, yhat))
mse = mean_squared_error(history, yhat)

print('Test RMSE: %.3f' % rmse)
print('Test MSE: %.3f' % mse)