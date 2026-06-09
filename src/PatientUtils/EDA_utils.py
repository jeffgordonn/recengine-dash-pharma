import pandas as pd
import numpy as np
import re
import os
from datetime import datetime as dt
from ..logging import logging_utils


class EDA:
    def __init__(self, store_outputs: bool | None = True, name: str | None = None):
        self.store_outputs = store_outputs
        if store_outputs:
            self.log_dir = input('Store Logs to dir location > ')
            self.edalog = logging_utils.log_it(self.log_dir)
            self.eda_data = {} ## store for use
        if name:
            self.name = name
        else:
            self.name = f'init@{dt.now().strftime("%d%m%Y")}'

    def __retrieveCSVPath__(self,display:bool=False):
        pdata_dir = rf"{os.environ['PATIENT_DATA_DIR']}/PatientData"
        csv_files = []
        for file in os.listdir(pdata_dir):
            # only grab the CSV
            # if str(os.path.splitext(file)).lower() == 'csv':
            path = os.path.join(file)
            csv_files.append(path)
            continue

        if display:
            for name in csv_files:
                print(name)
                with open(os.path.join(pdata_dir,name),'r') as file:
                    print(file.readline())
                print(50*'-')
                print()
        return pdata_dir

    def basicDescriptiveColumnEDA(self,filename:str,dir=__retrieveCSVPath__(),threshold:dict[str,float]={'PERCENT':0.25}):
        pathcsv = fr'{dir}/{filename}'
        df = pd.read_csv(pathcsv)
        # df.head()

        for col in df.columns:
            print(f'''
            Column: {col}
            {'-'*50}
            ''')
            print(df[col].describe())
            ## for thresholding to display the unique values
            length = df[col].notna().sum()
            dislength = df[col].nunique(dropna=True)
            # print(length)
            # print(dislength)
            if 'INT' in threshold:
                if (dislength <= threshold['INT']):
                    print(df[col].unique())
            elif 'PERCENT' in threshold:
                # print(threshold['PERCENT'])
                if dislength/length <= threshold['PERCENT']:
                    print(df[col].unique())
            else:
                print('Incorrect key for threshold, please use ->: [INT,PERCENT]')

            print()
            print()
        if self.store_outputs:
            self.eda_data[filename] = df
        return df

    filename = 'devices.csv'

    def __findStringColumns__(self,df:pd.DataFrame):
        return df.select_dtypes(include=['object','string']).columns

    def __dfExtractFromParentheses__(self,df:pd.DataFrame,col:str,return_map:bool=False):
        '''
        Meant to be used within a loop or on a single column
        '''                                                 ### There is a few columns I have identified seperate processes for processing them, skip them here
        if (df[str(col)].str.contains(r'\(',regex=True)) & (col not in ['UDI','ReasonDescription']):
            # creating map df
            df[f'{str(col)}Detail'] = df.str.extract(r'\((.*?)\)',expand=False) # grab parentheses data IF any
            df[str(col)] = df[str(col)].str.replace(r'\s*\(.*?\)','',regex=True).str.strip() # reset the og column to non-parentheses data
            df[f'{str(col)}DetailID'] = pd.factorize(f'{df[col]}Detail')[0]+1
            df[f'{str(col)}ID'] = pd.factorize(df[col])[0]+1
            map_df = df[
                [
                    # non-paren data
                    str(col),f'{str(col)}ID',
                    # paren data
                    f'{str(col)}Detail',f'{str(col)}DetailID'
                ]
            ].drop_duplicates().copy() # small extracts so space should not expand an insane amount
            if return_map:
                return map_df
        else:
            pass

    def __dictDfToCSVs__(
            dfdict:dict[pd.DataFrame],dir:str=__retrieveCSVPath__(),
            makenewdir:dict[bool,str]={'CreateSubDir':False,'DirName':'MapTables'},
            print_path:bool=False
    ):
        '''
        From the passed dictionary, this will take the key and create a csv of each value in the following pattern:

        # inside of a for loop for the keys
        f'{pdata_dir}/{dfdict[key]}.csv'
        '''
        if makenewdir['CreateSubDir']:
            subdir = os.path.join(dir,makenewdir['DirName'])
            if not os.path.exists(subdir):
                os.makedirs(subdir)
        for key in dfdict.keys():
            dfdict[key].to_csv(f'{subdir}/{key}.csv',index=False)
            if print_path:
                print(f'{subdir}/{key}.csv')

    def displayUniqueStringDataFromParentheses(
            self, df:pd.DataFrame, 
            options:dict[bool,bool]={'DictReturn':False,'toCSV':False},
            filename:str=filename
    ):
        '''
        Performing ETL on parentheses, extending original data to include these IDs.

        **PLEASE BEAWARE THIS WILL OVERWRITE THE FILE PASSED**

        Purpose 1: This will display all of the columns with string data that has parentheses enclosed text.
        Purpose 2: Using dfExtractFromParentheses() we will map the strings and their parentheses data to seperate columns and mapping tables,
          which I decided to in python since I had noticed this at this stage. Other string mapping can be taken care in SQL, I just prefer the
          regex interface in python. **PLEASE NOTE THAT THIS WILL OVERWRITE THE CSV FILES**. This is why in `activate_setup.txt` there is a backup
          folder created.
        Purpose 3: Return the map of dictionaries if there is a desire to analyze this further in python

        '''
        filename = os.path.splitext(filename)[0]
        approved_options_keys = {'DictReturn','toCSV'}
        if not set(options).issubset(approved_options_keys):
            raise KeyError(f'displayUniqueStringData(): option paramater must exist in the following approved keys:\n {','.join(approved_options_keys)}')
        for k,v in options.items():
            if not isinstance(bool(v),bool):
                raise ValueError(fr'displayUniqueStringDataFromParentheses(): {k} could not be interpretted as a boolean: {v}')

        stringcols = self.__findStringColumns__(df)
        dfmapdict = {}
        for col in stringcols:
            parendf = self.__dfExtractFromParentheses__(df,col)
            dfmapdict[f'{filename}_{col}'] = parendf

        for df in dfmapdict:
            for col in df.columns:
                with pd.option_context({'display.max_rows': None,'display.max_columns': None}):
                    print(df[col].nunique().head(len(df[col].nunique)))

        if self.store_outputs:
            for name, df  in dfmapdict.items():
                self.eda_data[name] = df

        if (bool(options['DictReturn'])) & (bool(options['toCSV'])):
            self.__dictDfToCSVs__(dfmapdict)
            return dfmapdict

        elif bool(options['DictReturn']):
            return dfmapdict
        elif bool(options['toCSV']):
            self.__dictDfToCSVs__(dfmapdict)

    def GSIExtract(
            self, df:pd.DataFrame,col:str,
            # making this a bit more readable
            pattern:str=
             r"\(01\)(?P<gtin_01>\d{14})\(11\)(?P<prod_date_11>\d{6})\(17\)" + 
             r"(?P<exp_date_17>\d{6})\(10\)(?P<lot_10>\d+)\(21\)(?P<serial_21>\d+)"
    ):
        '''
        Extract these special ID strings, return them in a mapped out df
        '''
        df[f'{str(col)}ID'] = pd.factorize(df[col])[0]+1
        gsi_df = df[[col],f'{str(col)}ID'].copy()
        extracted_gsi = gsi_df[col].str.extract(pattern)
        gsi_df = pd.concat([gsi_df,extracted_gsi],axis=1)
        if self.store_outputs:
            # this was really for a specific column so for now i am keeping it without a passed file name or origin name
            if f'{col}_gsi' not in self.eda_data:
                self.eda_data[f'{col}_gsi'] = gsi_df
            else:
                # muhahaha nearly as confusing but with some kind of date associable
                # lol i prolly should just add the column name, if there is more then 3 prolly will
                self.eda_data[f'{col}_gsi_{dt.now().strftime("%d%m%Y")}'] = gsi_df
        return gsi_df