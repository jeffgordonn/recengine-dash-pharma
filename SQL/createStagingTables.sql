
\c PATIENTS_STAGING;

CREATE TABLE DEVICES (
    "Start"  TIMESTAMPTZ NULL,
    "Stop"  TIMESTAMPTZ NULL,
    Patient TEXT NULL,
    Encounter TEXT NULL,
    Code TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL,
    Udi TEXT NULL
    GTIN TEXT NULL,
    ProdDate TEXT NULL,
    ExpDate TEXT NULL,
    Lot TEXT NULL,
    SerialID TEXT NULL
);

CREATE TABLE CLAIMS_TRANSACTIONS (
    ID UUID PRIMARY KEY NOT NULL,
    ClaimID UUID NULL,
    ChargeID TEXT NULL,
    PatientID UUID NULL,
    "Type" TEXT NULL,
    Amount NUMERIC NULL,
    Method TEXT NULL,
    FromDate TIMESTAMPTZ NULL,
    ToDate TIMESTAMPTZ NULL,
    PlaceOfService TEXT NULL,
    ProcedureCode TEXT NULL,
    Modifier1 TEXT NULL,
    Modifier2 TEXT NULL,
    DiagnosisRef1 INT NULL,
    DiagnosisRef2 INT NULL,
    DiagnosisRef3 INT NULL,
    DiagnosisRef4 INT NULL,
    Units INT NULL,
    DepartmentID TEXT NULL,
    Notes TEXT NULL,
    UnitAmount NUMERIC NULL,
    TransferOutID TEXT NULL,
    TransferType TEXT NULL,
    Payments NUMERIC NULL,
    Adjustments NUMERIC NULL,
    Transfers NUMERIC NULL,
    Outstanding NUMERIC NULL,
    AppointmentID TEXT NULL,
    LineNote TEXT NULL,
    PatientInsuranceID TEXT NULL,
    FeeScheduleID TEXT NULL,
    ProviderID TEXT NULL,
    SupervisingProviderID TEXT NULL
);

CREATE TABLE SUPPLIES (
    "DATE" DATE NULL,
    Patient TEXT NULL,
    Encounter TEXT NULL,
    Code TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL,
    Quantity INT NULL
);

CREATE TABLE CLAIMS (
    ID TEXT NULL,
    PatientID TEXT NULL,
    ProviderID TEXT NULL,
    PrimaryPatientInsuranceID TEXT NULL,
    SecondaryPatientInsuranceID TEXT NULL,
    DepartmentID TEXT NULL,
    PatientDepartmentID TEXT NULL,
    Diagnosis1 TEXT NULL,
    Diagnosis2 TEXT NULL,
    Diagnosis3 TEXT NULL,
    Diagnosis4 TEXT NULL,
    Diagnosis5 TEXT NULL,
    Diagnosis6 TEXT NULL,
    Diagnosis7 TEXT NULL,
    Diagnosis8 TEXT NULL,
    ReferringProviderID TEXT NULL,
    AppointmentID TEXT NULL,
    CurrentIllnessDate TIMESTAMPTZ NULL,
    ServiceDate TIMESTAMPTZ NULL,
    SupervisingProviderID TEXT NULL,
    Status1 TEXT NULL,
    Status2 TEXT NULL,
    StatusP TEXT NULL,
    Outstanding1 NUMERIC NULL,
    Outstanding2 NUMERIC NULL,
    OutstandingP NUMERIC NULL,
    LastBilledDate1 TIMESTAMPTZ NULL,
    LastBilledDate2 TIMESTAMPTZ NULL,
    LastBilledDateP TIMESTAMPTZ NULL,
    HealthcareClaimTypeID1 TEXT NULL,
    HealthcareClaimTypeID2 TEXT NULL
);

CREATE TABLE ENCOUNTERS (
    ID TEXT NULL,
    "Start"  TIMESTAMPTZ NULL,
    "Stop"  TIMESTAMPTZ NULL,
    Patient TEXT NULL,
    Organization TEXT NULL,
    "Provider"  TEXT NULL,
    Payer TEXT NULL,
    EncounterClass TEXT NULL,
    Code TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL,
    BaseEncounterCost NUMERIC NULL,
    TotalClaimCost NUMERIC NULL,
    PayerCoverage NUMERIC NULL,
    ReasonCode TEXT NULL,
    ReasonDescription TEXT NULL
);

CREATE TABLE CAREPLANS (
    ID TEXT NULL,
    "Start"  TIMESTAMPTZ NULL,
    "Stop"  TIMESTAMPTZ NULL,
    Patient TEXT NULL,
    Encounter TEXT NULL,
    Code TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL,
    ReasonCode TEXT NULL,
    ReasonDescription TEXT NULL,
    ReasDescParenDetail TEXT NULL
);

CREATE TABLE OBSERVATIONS (
    "Date" TIMESTAMPTZ NULL,
    Patient TEXT NULL,
    Encounter TEXT NULL,
    Category TEXT NULL,
    Code TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL,
    Value TEXT NULL,
    Units TEXT NULL,
    "Type"  TEXT NULL
);

CREATE TABLE PAYERS (
    ID TEXT NULL,
    Name TEXT NULL,
    "Address"  TEXT NULL,
    City TEXT NULL,
    "State" Headquartered TEXT NULL,
    Zip TEXT NULL,
    Phone TEXT NULL,
    AmountCovered NUMERIC NULL,
    AmountUncovered NUMERIC NULL,
    Revenue NUMERIC NULL,
    CoveredEncounters INT NULL,
    UncoveredEncounters INT NULL,
    CoveredMedications INT NULL,
    UncoveredMedications INT NULL,
    CoveredProcedures INT NULL,
    UncoveredProcedures INT NULL,
    CoveredImmunizations INT NULL,
    UncoveredImmunizations INT NULL,
    UniqueCustomers INT NULL,
    QolsAvg NUMERIC NULL,
    MemberMonths INT NULL
);

CREATE TABLE IMAGING_STUDIES (
    ID TEXT NULL,
    "Date" TIMESTAMPTZ NULL,
    Patient TEXT NULL,
    Encounter TEXT NULL,
    SeriesUid TEXT NULL,
    BodysiteCode TEXT NULL,
    BodysiteDescription TEXT NULL,
    ModalityCode TEXT NULL,
    ModalityDescription TEXT NULL,
    InstanceUid TEXT NULL,
    SopCode TEXT NULL,
    SopDescription TEXT NULL,
    ProcedureCode TEXT NULL
);

CREATE TABLE IMMUNIZATIONS (
    TIMESTAMPTZ DATE NULL,
    Patient TEXT NULL,
    Encounter TEXT NULL,
    Code TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL,
    BaseCost NUMERIC NULL
);

CREATE TABLE PAYER_TRANSITIONS (
    Patient TEXT NULL,
    MemberID TEXT NULL,
    "Start" Year INT NULL,
    EndYear INT NULL,
    Payer TEXT NULL,
    SecondaryPayer TEXT NULL,
    "Ownership"  TEXT NULL,
    OwnerName TEXT NULL
);

CREATE TABLE CONDITIONS (
    "Start"  TIMESTAMPTZ NULL,
    "Stop"  TIMESTAMPTZ NULL,
    Patient TEXT NULL,
    Encounter TEXT NULL,
    Code TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL
);

CREATE TABLE ORGANIZATIONS (
    ID TEXT NULL,
    Name TEXT NULL,
    "Address"  TEXT NULL,
    City TEXT NULL,
    "State"  TEXT NULL,
    Zip TEXT NULL,
    Lat NUMERIC NULL,
    Lon NUMERIC NULL,
    Phone TEXT NULL,
    Revenue NUMERIC NULL,
    Utilization INT NULL
);

CREATE TABLE PROCEDURES (
    "Start"  TIMESTAMPTZ NULL,
    "Stop"  TIMESTAMPTZ NULL,
    Patient TEXT NULL,
    Encounter TEXT NULL,
    Code TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL,
    BaseCost NUMERIC NULL,
    ReasonCode TEXT NULL,
    ReasonDescription TEXT NULL
);

CREATE TABLE "Provider" S (
    ID TEXT NULL,
    Organization TEXT NULL,
    "Name" TEXT NULL,
    Gender TEXT NULL,
    Speciality TEXT NULL,
    "Address"  TEXT NULL,
    City TEXT NULL,
    "State"  TEXT NULL,
    Zip TEXT NULL,
    Lat NUMERIC NULL,
    Lon NUMERIC NULL,
    Utilization INT NULL
);

CREATE TABLE PATIENTS (
    ID TEXT NULL,
    BirthDate TIMESTAMPTZ NULL,
    DeathDate TIMESTAMPTZ NULL,
    Ssn TEXT NULL,
    Drivers TEXT NULL,
    Passport TEXT NULL,
    Prefix TEXT NULL,
    "First"  TEXT NULL,
    "Last"  TEXT NULL,
    Suffix TEXT NULL,
    Maiden TEXT NULL,
    Marital TEXT NULL,
    Race TEXT NULL,
    Ethnicity TEXT NULL,
    Gender TEXT NULL,
    BirthPlace TEXT NULL,
    "Address"  TEXT NULL,
    City TEXT NULL,
    "State"  TEXT NULL,
    County TEXT NULL,
    Zip TEXT NULL,
    Lat NUMERIC NULL,
    Lon NUMERIC NULL,
    HealthcareExpenses NUMERIC NULL,
    HealthcareCoverage NUMERIC NULL
);

CREATE TABLE ALLERGIES (
    "Start"  TIMESTAMPTZ NULL,
    "Stop"  TIMESTAMPTZ NULL,
    Patient TEXT NULL,
    Encounter TEXT NULL,
    Code TEXT NULL,
    "System" TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL,
    "Type"  TEXT NULL,
    Category TEXT NULL,
    Reaction1 TEXT NULL,
    Description1 TEXT NULL,
    Severity1 TEXT NULL,
    Reaction2 TEXT NULL,
    Description2 TEXT NULL,
    Severity2 TEXT NULL
);

CREATE TABLE MEDICATIONS (
    "Start"  TIMESTAMPTZ NULL,
    "Stop"  TIMESTAMPTZ NULL,
    Patient TEXT NULL,
    Payer TEXT NULL,
    Encounter TEXT NULL,
    Code TEXT NULL,
    "Description" TEXT NULL,
    DescParenDetail TEXT NULL,
    BaseCost NUMERIC NULL,
    PayerCoverage NUMERIC NULL,
    Dispenses INT NULL,
    TotalCost NUMERIC NULL,
    ReasonCode TEXT NULL,
    ReasonDescription TEXT NULL
);
