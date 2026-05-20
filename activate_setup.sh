#!/usr/bin/env bash

# Create repo in downloads
cd "$HOME/Downloads" || exit 1
mkdir -p PatientData/PatientData
mkdir -p PatientData/PatientData_Backup

# Extract data and put it in the PatientData Location
curl -L "https://mitre.box.com/shared/static/aw9po06ypfb9hrau4jamtvtz0e5ziucz.zip" -o /tmp/patients_data.zip
unzip /tmp/patients_data.zip -d ./Downloads/PatientData/PatientData

CREATE_BACKUP=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --create-backup)
      CREATE_BACKUP=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Main unzip
unzip /tmp/patients_data.zip -d "$HOME/Downloads/PatientData/PatientData"

# Optional backup unzip
if [[ "$CREATE_BACKUP" == true ]]; then
  mkdir -p "$HOME/Downloads/PatientData/PatientData_Backup"
  unzip /tmp/patients_data.zip -d "$HOME/Downloads/PatientData/PatientData_Backup"
fi

## create the .gitignore?
## what else

### Set up Python requirements etc
cd "$HOME/Downloads/PatientData" || exit 1
python3 -m venv Patients
source Patients/bin/activate
pip install -r requirements.txt

deactivate