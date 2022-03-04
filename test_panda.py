import MetaTrader5 as mt5
from pandas import to_datetime, DataFrame
import matplotlib.pyplot as plt

symbol = "EURUSDm"

if not mt5.initialize():
    print("initialize() failed")
    mt5.shutdown()

rates = mt5.copy_rates_from_pos(symbol, mt5.TIMEFRAME_D1, 0, 1000)
mt5.shutdown()

rates = DataFrame(rates)
rates['time'] = to_datetime(rates['time'], unit='s')
rates = rates.set_index(['time'])

plt.figure(figsize = (15,10))
plt.plot(rates.close)
plt.show()