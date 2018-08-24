# -*- coding: utf-8 -*-
"""
Created on Tue Jul 24 12:13:12 2018

@author: Arthur
"""

def collect_cryptocurrencies_prices(sleepTime = 900,
                                    saveToDatabase = False):
    import cx_Oracle
    import requests
    import time
    import datetime

    from pathlib import Path


    
    #URL used to request data
    url = 'https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH,XRP,BCH,LTC&tsyms=USD'

    #infinite loop
    while True:
        
        #HTTP request
        request = requests.get(url)
        
        #Current date
        current_date = str(datetime.datetime.today().strftime('%Y-%m-%d %H:%M:%S')) 
        current_date_format = 'YYYY-MM-DD HH24:MI:SS'
    
        if request.status_code == 200: #successful request
            prices         = request.json()
            BTC = prices['BTC']['USD']
            ETH = prices['ETH']['USD']
            XRP = prices['XRP']['USD']
            BCH = prices['BCH']['USD']
            LTC = prices['LTC']['USD']
        else:
            print("Error durring the HTTP request. Status code:" + str(request.status_code))
            break
        
        if saveToDatabase in ('TRUE', 'true', 'True', 't') : #saving data to the database
    
            #connecting to FSB database
            connection = cx_Oracle.connect("carvalag", 
                                           "m7ami", 
                                           "sbaoracle.sba.muohio.edu:1521/oracle.sba.muohio.edu")
            cursor     = connection.cursor()
                       
            cursor.execute("INSERT INTO CRYPTOCURRENCIES VALUES (" \
                             + str(BTC) +  ", " + str(ETH) +  ", " + str(XRP) +  ", " \
                             + str(BCH) +  ", " + str(LTC) +  ", "   \
                             + "TO_DATE ( '" + current_date + "', '" + current_date_format + "'))")
            cursor.execute('COMMIT')
            print('Prices sucessfully added to the database at: ' + current_date)
        
        else :
            
            if Path("./data.csv").exists():
                row = str(BTC) + ',' + str(ETH) + ',' + str(XRP) + ',' + str(BCH) + ',' + str(LTC) + ',' + current_date + '\n'
            else:
                row = 'BTC,ETH,XRP,BCH,LTC,Date \n' \
                        + str(BTC) + ',' + str(ETH) + ',' + str(XRP) + ',' \
                        + str(BCH) + ',' + str(LTC) + ',' + current_date + '\n'

            csv_file   = open('./data.csv','a')
            csv_file.write(row)
            csv_file.close()
            
            print('Prices sucessfully added to the csv file at: ' + current_date)


        #code sleeps    
        time.sleep(sleepTime)
    

#Example of usage as script: python cryptocurrencies_realtime_data_collection 5 true
if __name__ == "__main__":
    import sys
    collect_cryptocurrencies_prices(int(sys.argv[1]), sys.argv[2])