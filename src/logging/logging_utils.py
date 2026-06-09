import os
from datetime import date

class log_it:
    def __init__(self, dir):
        if os.path.exists(dir):
            self.dir = os.path.join(dir)
        else:
            raise FileNotFoundError(f'{dir} was not found.\n\nPlease recheck whether the path exists or if there was a typo')
    
    def createSubDirectory(
            self,subdir_name:str|None = None, return_path: str | None = None
    ):
        if os.path.exists(os.path.join((self.dir,subdir_name))):
            print('SubDirectory already exists in this directory. Provide new folder name')
        else:
            os.mkdir(self.dir,subdir_name)
            if os.path.exists(os.path.join((self.dir,subdir_name))):
                print('SubDirectory created')
            else:
                raise FileNotFoundError('Sub-Directory was unable to be created')
            
    def __create_file__(
            self, file_name:str|None = None, 
            dir: str | None = None, content: str = ''
    ):
        if dir is None:
            dir = self.dir
        with open(os.path.join(dir,file_name),'w') as file:
            file.write(content)

    def __handle_missing_dirfile__(
            self, default: str, dir:str | None = None, file:str | None = None
    ):
        if dir is None:
            dir = self.dir
        if file is None:
            file = default
            proceed = input('No file was specified: Proceed? Y/N\n\n')
            if 'Y' in proceed:
                if not os.path.exists(dir,file):
                    self.__create_file__(file_name=file,dir=dir)
                print(f'File will be loaded to {file} in {dir}')
                return dir, file
            else:
                raise FileExistsError('Return desired file name')
        else:
            return dir, file
        

    def logRun(
            self, model_name:str|None = 'modelunspecified',
            model:any = None, metrics:dict | None = None, notes:str | None = None, 
            dir: str | None = None, file: str | None = None
    ):
        # I might update this but i think it would be reasonable this to store in txt
        dir, file = self.__handle_missing_dirfile__('modeldata_dump.txt',dir,file)

        with open(os.path.join(dir,file),'a') as file:
            file.write(f'{date.now()} - {model_name}\n')
            file.write(f'{50*'-'}')
            file.write(str(metrics))
            
    def logError(
            self, error:str|None = None, error_message:str|None = None, 
            error_detail:str | None = None, dir: str | None = None,
            file: str | None = None
    ):
        dir, file = self.__handle_missing_dirfile__('errordata_dump.log',dir,file)

        with open(os.path.join(dir,file),'a') as log:
            log.write(f'{date.now()}: Error Type - {error}\n')
            file.write(f'{50*'-'}')
            log.write(f'Error content: {error_message}')
            if error_detail:
                log.write(f'Additional Detail Provided\n\n')



    def logEvent(
            self, event_type: str | None, event_details:dict | None = None,
            dir: str | None = None, file: str | None = None
    ):
        dir, file = self.__handle_missing_dirfile__('eventdata_dump.log')

        with open(os.path.join(dir,file),'a') as log:
            log.write(f'{date.now()}: Event Type - {event_type}\n')
            if event_details:
                file.write(f'{50*'-'}')
                log.write(f'Additional Detail Provided\n\n')
                log.write(str(event_details))
        

    