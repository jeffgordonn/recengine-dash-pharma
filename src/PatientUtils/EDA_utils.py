import pandas as pd
import numpy as np
import re
import os

def retrieveCSVPath(display:bool=False):
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

def basicDescriptiveColumnEDA(filename:str,dir=retrieveCSVPath(),threshold:dict[str,float]={'PERCENT':0.25}):
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
    return df

filename = 'devices.csv'

def findStringColumns(df:pd.DataFrame):
    return df.select_dtypes(include=['object','string']).columns

def dfExtractFromParentheses(df:pd.DataFrame,col:str,RETURN_MAP:bool=False):
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
        if RETURN_MAP:
            return map_df
    else:
        pass

def dictDfToCSVs(
        dfdict:dict[pd.DataFrame],dir:str=retrieveCSVPath(),
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
        df:pd.DataFrame, options:dict[bool,bool]={
            'DictReturn':False,
            'toCSV':False
        },filename:str=filename
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

    stringcols = findStringColumns(df)
    dfmapdict = {}
    for col in stringcols:
        dfExtractFromParentheses(df,col)

    dfmapdict[filename] = df

    for df in dfmapdict:
        for col in df.columns:
            with pd.option_context({'display.max_rows': None,'display.max_columns': None}):
                df[col].nunique().head(len(df[col].nunique))

    if (bool(options['DictReturn'])) & (bool(options['toCSV'])):
        dictDfToCSVs(dfmapdict)
        return dfmapdict

    elif bool(options['DictReturn']):
        return dfmapdict
    elif bool(options['toCSV']):
        dictDfToCSVs(dfmapdict)

def GSIExtract(
        df:pd.DataFrame,col:str,
        # making this a bit more readable
        pattern:str=
         r"\(01\)(?P<gtin_01>\d{14})\(11\)(?P<prod_date_11>\d{6})\(17\)" + 
         r"(?P<exp_date_17>\d{6})\(10\)(?P<lot_10>\d+)\(21\)(?P<serial_21>\d+)"
):
    df[f'{str(col)}ID'] = pd.factorize(df[col])[0]+1
    gsi_df = df[[col],f'{str(col)}ID'].copy()
    extracted_gsi = gsi_df[col].str.extract(pattern)
    return pd.concat([gsi_df,extracted_gsi],axis=1)