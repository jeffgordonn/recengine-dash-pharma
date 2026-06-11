import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import numpy as np
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from datetime import datetime as dt
import ML_utils as mut

class connectToPostgre:
    def __init__(self,env_path: str = '.env'):
        self.connection = self.returnPGConnection(env_path)

    def returnPGConnection(self,env_path: str = ".env"):
        load_dotenv(env_path)

        user = os.getenv("POSTGRES_USER")
        password = os.getenv("POSTGRES_PASSWORD")
        host = os.getenv("POSTGRES_HOST", "localhost")
        port = os.getenv("POSTGRES_PORT", "5432")
        db = os.getenv("POSTGRES_DB")
        if not all([user,password,host,port,db]):
            raise ValueError('Missing postgreSQL env value')
        
        connection = (
            f'postgresql+psycopg2://{user}:{password}@{host}:{port}/{db}'
        )

        return create_engine(connection)


    def retrieveSQLQueryFromFile(
        self,query_file:str,query_dir:str= os.path.join(os.environ['PATIENT_DATA_DIR'],"SQL/Data_Scripts")
    ):
        '''
        If the same directory structure is maintained, just specify the file name for the query
            else
        Provide directory as well
        '''
        # pull the SQL file contents into a readable string variable
        with open(os.path.join(query_dir,query_file),'r') as query:
            query_str = query.read()

        return query_str
            
    def retrieveSQLData(self,query:str):
        '''
        Query should be provided in its entiriety from user. The `retrieveSQLQuery` is a nice way to do this 
        if the SQL queries are already stored / you would rather right them in their file and then execute them
        '''
        return pd.read_sql(query,self.connection)
    
    def killConnection(self):
        '''
        The outright killing of the connection (*cries for loss*)
        '''
        self.connection.dispose()