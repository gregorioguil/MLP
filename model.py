from tensorflow.keras.models import *

class Model(object):
    def __init__(self, n_steps:int, symbol:str, period:int) -> None:
        super().__init__()
        self.n_steps = n_steps
        self.model = load_model(r'C:\Users\Micro\Documents\MLP\model_train_'+symbol+'.h5')

    def predict(self, data):
        return(self.model.predict(data.reshape((1, self.n_steps))).flatten()[0])