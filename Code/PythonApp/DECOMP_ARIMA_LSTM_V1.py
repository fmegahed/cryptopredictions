# In[1]:
## Packages and Models
import sys
import datetime as dt
import numpy as np

import pandas as pd 
from pandas import DataFrame

import matplotlib.pyplot as plt

import plotly.offline as py
py.init_notebook_mode (connected = True)

from keras.models import Sequential
from keras.layers import Dense, LSTM
from keras.callbacks import EarlyStopping

from sklearn.preprocessing import MinMaxScaler

from statsmodels.tsa.arima_model import ARIMA
import statsmodels.api as sm


import itertools
import warnings


# In[2]:
#The function takes two arguments: the dataset, which is a NumPy array that we 
#want to convert into a dataset, and the look_back, which is the number of 
#previous time steps to use as input variables to predict the next time period 
#— in this case defaulted to 1.#

# convert an array of values into a dataset matrix
def create_dataset(dataset, look_back=1, init = -1):
    dataX, dataY = [], []
    if not init == -1:
        dataX.append(init)
        dataY.append(dataset[0])
        
    for i in range(len(dataset)-look_back-1):
        a = dataset[i:(i+look_back), 0]
        dataX.append(a)
        dataY.append(dataset[i + look_back, 0])
    return np.array(dataX), np.array(dataY)

# In[3]:
    
def ARIMA_prediction(train):
    ## Find the pdq tuple that generates teh lowes aic
    model = ARIMA(train, order=(5,1,0))
    d = range(0, 2)
    p = q = range(0, 6)

    # Generate all different combinations of p, q and q triplets
    pdq = list(itertools.product(p, d, q))
    warnings.filterwarnings("ignore") # specify to ignore warning messages
    critVals = list()
    modArgs = list()
    for param in pdq:
        try:
            mod = sm.tsa.statespace.SARIMAX(train, order=param)
            results = mod.fit()
            critVals.append(results.aic)
            modArgs.append(param)
        except:
            continue
    
    # Retrieve pdq settings for lowest aic
    params = modArgs[min(range(len(critVals)), key=critVals.__getitem__)]
    model = ARIMA(train, order = params)
    model_fit = model.fit(disp = 0)
    yforecast_arima = model_fit.forecast()[0]
    return yforecast_arima
    
# In[4]:
def LSTM_prediction(training_set, test_set, holdout_high_VC):
    ### Apply LSTM Recurrent Neural Networks for the high part
    training_set = np.reshape(training_set, (len(training_set), 1))
    test_set = np.reshape(test_set, (len(test_set), 1))
    holdout_high_VC_set = np.reshape(holdout_high_VC, (len(holdout_high_VC), 1))
    
    #scale datasets
    scaler = MinMaxScaler()
    training_set = scaler.fit_transform(training_set)
    test_set = scaler.transform(test_set)
    holdout_high_VC_set = scaler.transform(holdout_high_VC_set)
    
    # create datasets which are suitable for time series forecasting
    X_train, Y_train = create_dataset(training_set, 1)
    X_test, Y_test = create_dataset(test_set, 1)
    X_holdout_high_VC, Y_holdout_high_VC = create_dataset(holdout_high_VC_set, 1, test_set[-1])
    
    # reshape input to be [samples, time steps, features]
    X_train = np.reshape(X_train, (len(X_train), 1, X_train.shape[1]))
    X_test = np.reshape(X_test, (len(X_test), 1, X_test.shape[1]))
    
    X_holdout_high_VC = np.reshape(X_holdout_high_VC, (len(X_holdout_high_VC), 1, X_holdout_high_VC.shape[1]))
    # create and fit the LSTM network
    model = Sequential()
    model.add(LSTM(256, return_sequences=True, input_shape=(X_train.shape[1], X_train.shape[2])))
    model.add(LSTM(256))
    model.add(Dense(1))
    
    
    # compile and fit the model
    model.compile(loss='mean_squared_error', optimizer='adam')
    model.fit(X_train, Y_train, epochs=100, batch_size=16, shuffle=False, verbose = 0,
                    validation_data=(X_test, Y_test),
                    callbacks = [EarlyStopping(monitor='val_loss', min_delta=5e-5, patience=10, verbose=1)])
    
    
    holdoutPredict = model.predict(X_holdout_high_VC)
    holdoutPredict = scaler.inverse_transform(holdoutPredict)
    
    return holdoutPredict[0], test_set[0]

# In[5]:
## Main Function
def ARIMA_LSTM(train, holdout): 
    #Divide the data into high and low variance
    s = pd.Series(train['close'])
  
    low_VC = s.ewm(alpha = 0.6).mean()
    high_VC = s - low_VC
    
    holdout_s = pd.Series(holdout['close'])
    holdout_low_VC = holdout_s.ewm(alpha = 0.6).mean().tolist()
    holdout_high_VC = (holdout_s - holdout_low_VC).tolist()
           
    ### ARIMA part on low
    yforecast_arima = 0
    yforecast_arima = ARIMA_prediction(low_VC)
    
#    print("yforecast_arima------")
#    print(yforecast_arima)
#    
#    print("holdout_df1")
#    print(holdout_low_VC[0])


     ##Divide the training data 90% & 10%
    training_idx = int(train.shape[0]*0.9)
    low_train = low_VC[:training_idx]
    low_test = low_VC[training_idx:]
    high_train = high_VC[:training_idx].tolist() # format (y - y_ses) as a list for LSTM routine
    high_test = high_VC[training_idx:].tolist()
    
    ### LSTM part on high
    holdoutPredict, holdout_high_VC = LSTM_prediction(high_train, high_test, holdout_high_VC)
    
    
#    print("holdoutPredict------")
#    print(holdoutPredict)
#    
#    print("holdout_df1")
#    print(holdout_high_VC)
   
    
    return yforecast_arima[0], holdout_low_VC[0], holdoutPredict[0], holdout_high_VC



# In[4]:
##Read the csv file
df = pd.read_csv ("crypto-markets.csv", na_values = ['NA', '?'])
df['date'] = pd.to_datetime(df['date'], format='%Y-%m-%d')
df['hlc_average'] = (df['high'] + df['low'] ) / 2

#df['hlc_average'] = (df['high'] + df['low'] + df['close']) / 3
#df['ohlc_average'] = (df['open'] + df['high'] + df['low'] + df['close']) / 4

##Get the Bitcoin data
bitcoin = df[df['name'] == 'Bitcoin'].copy()
#bitcoin['target'] = bitcoin['close'].shift(-1)


##Divide the data 70% for training and 30% testing
#cutIdx = len(bitcoin[bitcoin['date']< dt.date(2018, 2, 27)])
cutIdx = int(len(bitcoin['date'])*0.7)
arema_pred = []
low_VC = []
lstm_pred = []
high_VC = []


for i in range(0, 3):#len(bitcoin['date']) - cutIdx - 1):
    bit_train = bitcoin[:cutIdx + i] # sets for ARIMA routine
    bit_holdout = bitcoin[cutIdx + i:]
    print("Training set has {} observations.".format(len(bit_train)))
    print("Test set has {} observations.".format(len(bit_holdout)))
    
    
    ap, l, lstmp, h = ARIMA_LSTM (bit_train, bit_holdout)
    
    arema_pred.append(ap)
    low_VC.append(l)
    lstm_pred.append(lstmp)
    high_VC.append(h)

target = [low_VC[i]+high_VC[i] for i in range(len(high_VC))]
pred = [arema_pred[i]+lstm_pred[i] for i in range(len(arema_pred))]
plt.plot(arema_pred)
plt.plot(low_VC)
plt.plot(lstm_pred)
plt.plot(high_VC)
plt.plot(target)
plt.plot(pred)
plt.plot([arema_pred[i]+lstm_pred[i] for i in range(len(lstm_pred))])
plt.show()

plt.plot([abs(target[i]-pred[i]) for i in range(len(pred))])
plt.show()


