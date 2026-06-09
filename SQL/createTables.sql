USE PATIENTSDW;

/*
There is A LOT OF DIFFERENT data which has repeatable values for mapping tables,
please remind yourself to check for redundant mapping tables and use an insert into with the new values
(say through an except)
*/
/*
I am not using create dates or modify date columns quite literally only because this is not active. Personally would
suggest some kind of create/change tracking mechanism in a live production DB 
*/


CREATE TABLE MASTER_STATE (
    StateID SERIAL PRIMARY KEY,
    [State] TEXT -- revisit length
    --, [Abbrev] TEXT 
);

CREATE TABLE MASTER_CITY (
    CityID SERIAL PRIMARY KEY,
    [City] TEXT -- revisit length
);

CREATE TABLE MASTER_COUNTY (
    CountyID SERIAL PRIMARY KEY,
    [County] TEXT -- revisit length
);

CREATE TABLE MASTER_ADDRESS (
    AddressID SERIAL PRIMARY KEY,
    [Address] TEXT -- revisit length
    
);

CREATE TABLE MASTER_GEO (
    CSCID SERIAL PRIMARY KEY,
    CityID INT REFERENCES MASTER_CITY(CityID),
    CountyID INT REFERENCES MASTER_COUNTY(CountyID),
    StateID INT REFERENCES MASTER_STATE(StateID),
    Zip INT,
    LAT FLOAT,
    LON FLOAT,
    UNIQUE(CityID,CountyID,StateID)
);

CREATE TABLE MASTER_NAME (
    NameID SERIAL PRIMARY KEY,
    [Name] TEXT,
    FLMNameFlag BOOLEAN, -- True: First, False: Last, NULL: MaidenName
);

-- Yes, this does makes some string replication BUT, I think it makes sense to store these together
CREATE TABLE MASTER_PATIENT_DEMODETAILS (
    SPGM_ID SERIAL PRIMARY KEY,
    Suffix TEXT,
    Prefix TEXT,
    Gender BOOLEAN,
    Married BOOLEAN
); -- This should not produce a massive replication but yes it does produce a little

CREATE TABLE MASTER_ETHNICITY (
    EthID SERIAL PRIMARY KEY,
    Ethncity TEXT NOT NULL,
    RaceHispanic BOOLEAN
);

CREATE TABLE MASTER_ORGNAMES (
    OrgID UUID NOT NULL PRIMARY KEY,
    OrgName TEXT
);

CREATE TABLE MASTER_PHONE (
    PhoneID SERIAL,
    PhoneNumber TEXT
);

CREATE TABLE MASTER_PROVIDER_DETAILS (
    ProviderID UUID NOT NULL PRIMARY KEY,
    ProviderFName TEXT,
    ProviderLName TEXT,
    Speciality TEXT,
    Gender BOOLEAN
);

---------------------------------------------------------------------------------------------------------------------
/*###################################################################################################################

                                                MASTER TABLES ABOVE

###################################################################################################################*/
---------------------------------------------------------------------------------------------------------------------

CREATE TABLE PATIENTS (
    PatientID UUID NOT NULL PRIMARY KEY,
    Healthcare_Expense FLOAT,
    Healthcare_Coverage FLOAT
);

/*
---- Need to make a seperate, more restrictive DB for this type of data
CREATE TABLE PATIENTS_IDENTIFICATION (
    PatientID UUID NOT NULL PRIMARY KEY REFERENCES PATIENTS(PatientID) ON DELETE CASCADE,
    SSN UUID NOT NULL,
    Driver TEXT UUID,
    Passport TEXT UUID
)
*/
CREATE TABLE PATIENTS_GEOGRAPHIC_DATA (
    PatientID UUID NOT NULL PRIMARY KEY REFERENCES PATIENTS(PatientID) ON DELETE CASCADE,
    AddressID INT NOT NULL,
    CityID INT NOT NULL,
    StateID INT NOT NULL, -- will need to map these IDs
    CountyID INT NOT NULL, -- will need to map these IDs WITH State attached
    Zip INT NOT NULL,
    LAT FLOAT,
    LON FLOAT
);

CREATE TABLE PATIENTS_DEMOGRAPHIC_DATA (
    PatientID UUID NOT NULL PRIMARY KEY REFERENCES PATIENTS(PatientID) ON DELETE CASCADE,
    SPGM_ID INT NOT NULL REFERENCES MASTER_PATIENT_DEMODETAILS(SPGM_ID) ON DELETE RESTRICT,
    EtheID INT NOT NULL REFERENCES MASTER_PATIENT_DEMODETAILS(SPGM_ID) ON DELETE RESTRICT
);

CREATE TABLE PATIENTS_DETAILS (
    PatientID UUID NOT NULL PRIMARY KEY REFERENCES PATIENTS(PatientID) ON DELETE CASCADE,
    FNameID INT REFERENCES MASTER_NAME(NameID) ON DELETE SET NULL, -- will need to map these IDs
    LnameID INT REFERENCES MASTER_NAME(NameID) ON DELETE SET NULL, -- will need to map these IDs
    MaidenNameID  REFERENCES MASTER_NAME(NameID) ON DELETE SET NULL INT,
    Gender BOOLEAN,
    BirthplaceID INT NOT NULL, -- will need to map these IDs
    Birthplace TEXT
);


CREATE TABLE ORGANIZATIONS (
    OrgID UUID NOT NULL PRIMARY KEY,
    CSCID INT REFERENCES MASTER_GEO(CSCID) ON DELETE RESTRICT,
    PhoneID INT,
    -- No revenue (all 0s) is seen in EDA, we will not incorporate
    Utilization INT
);

CREATE TABLE PROVIDERS (
    ProviderID UUID NOT NULL PRIMARY KEY
    OrgID UUID NOT NULL REFERENCES ORGANIZATIONS(OrgID) DELETE ON CASCADE, -- should be able to reuse from GenderID
    SpecialityID INT, -- will need to map these IDs
    CSCID INT REFERENCES MASTER_GEO(CSCID) ON DELETE RESTRICT,
    Utilization INT
);

-------======================= STOPPED HERE =============================-------
CREATE TABLE PAYERS (
    PayerID UUID NOT NULL PRIMARY KEY, -- might need to change this, it seems to be unique but if hash does not
                                       -- maintain difference across states, we might need to create a composite prim key
    PayerNameID INT NOT NULL,

);

CREATE TABLE PAYERS_CONTACT_DATA (
    PayerID UUID NOT NULL PRIMARY KEY REFERENCES PAYERS(PayerID) ON DELETE CASCADE,
    AddressID INT NOT NULL,
    Zip INT NOT NULL,
    CityID SMALLINT NOT NULL,
    StateHQID SMALLINT NOT NULL,
    Phone TEXT
);

CREATE TABLE PAYERS_COVERAGE_DETAILS (
    PayerID UUID NOT NULL PRIMARY KEY REFERENCES PAYERS(PayerID) ON DELETE CASCADE,
    AmountCovered FLOAT,
    AmountUncovered FLOAT,
    [Coverage%] FLOAT, -- calc column  vvvvv all with % below are calc columns
    Revenue FLOAT,
    CoveredEncounters INT,
    UncoveredEncounters INT,
    [EncounterCoverage%] FLOAT,
    CoveredMedications INT,
    UncoveredMedications INT,
    [MedicationsCoverage%] FLOAT,
    CoveredProcedures INT,
    UncoveredProcedures INT,
    [ProceduresCoverage%] FLOAT,
    CoveredImmunizations INT,
    UncoveredImmunizations INT,
    [ImmunizationsCoverage%] FLOAT,
    UniqueCustomers INT,
    CoveragePerCustomer FLOAT,
    QOLS_AVG FLOAT,
    MemberMonths INT
)

CREATE TABLE ENCOUNTERS (
    EncounterID UUID NOT NULL PRIMARY KEY,
    [Start] TIMESTAMP,
    [Stop] TIMESTAMP,
    PatientID UUID NOT NULL REFERENCES PATIENTS(PatientID) ON DELETE SET NULL,
    OrgID UUID NOT NULL REFERENCES ORGANIZATIONS(OrgID),
    ProviderID NOT NULL REFERENCES PROVIDERS(ProviderID),
    PayerID NOT NULL REFERENCES PAYERS(PayerID),
    EncounterClassID SMALLINT,  -- will need to map these IDs
    Code INT,
    DescriptionID SMALLINT,
    DescriptionDetailID SMALLINT,
    BaseEncounterCost FLOAT,
    TotalClaimCost FLOAT,
    Payer_Coverage FLOAT,
    ReasonCode INT, -- will work as mapping join
    -- ReasonDescriptionID INT -- this will be added to the non-paren extract list since reasoncode already does the join we need
);

-- actually think this is fine to keep in a large table: this should absolutely be unique.
-- We will add a create date / update date as well
CREATE TABLE CLAIMS (
    ClaimID UUID NOT NULL PRIMARY KEY,
    PatientID UUID NOT NULL REFERENCES PATIENTS(PatientID) ON DELETE SET NULL,
    ProviderID UUID NOT NULL REFERENCES PROVIDERS(ProviderID) ON DELETE CASCADE,
    PrimaryPatientInsuranceID UUID NOT NULL, -- this likely references payers
    SecPatientInsuranceID UUID,
    DeptID SMALLINT,
    PatientDeptID INT,
    DiagnosisCode1 INT NOT NULL,
    DiagnosisCode2 INT,
    DiagnosisCode3 INT, -- I am not finding float samples but we can revisit this if there are decimal values for these 3
    DiagnosisCode4 INT,
    DiagnosisCode5 INT,
    DiagnosisCode6 INT,
    DiagnosisCode7 INT, -- I am not finding float samples but we can revisit this if there are decimal values for these 3
    DiagnosisCode8 INT,
    -- ReferringProviderID INT, -- All NULLs according to EDA
    AppointmentID UUID NOT NULL,
    CurrentIllnessDate TIMESTAMP,
    ServiceDate TIMESTAMP,
    SupervisingProviderID UUID,
    Status1ID SMALLINT, -- NULL: nan, 0:BILLED, 1:CLOSED
    Status2ID SMALLINT, -- NULL: nan, 0:BILLED, 1:CLOSED
    StatusPID SMALLINT, -- NULL: nan, 0:BILLED, 1:CLOSED
    -- all of the outstanding columns were zero or nan, does not make sense to include for scope of project
    LastBillDate1 TIMESTAMP,
    LastBillDate2 TIMESTAMP,
    LastBillDateP TIMESTAMP,
    HealthCareClaimTypeID1 SMALLINT,
    HealthCareClaimTypeID2 SMALLINT,
    CreateDate TIMESTAMP ON CREATE DEFAULT NOW(),
    UpdateDate TIMESTAMP ON UPDATE DEFAULT NOW()
);



CREATE TABLE CLAIMSTRANSACTIONS (
    TransactionID UUID NOT NULL PRIMARY KEY,
    ClaimID UUID NOT NULL REFERENCES CLAIMS(ClaimID) ON DELETE CASCADE,
    ChargeID FLOAT,
    PatientID UUID NOT NULL REFERENCES PATIENTS(PatientID) ON DELETE SET NULL,
    TransType SMALLINT,  -- will need to map these IDs
    Amount FLOAT,
    PaymentMethodID SMALLINT,  -- will need to map these IDs
    FromDate TIMESTAMP,
    ToDate TIMESTAMP,
    PlaceOfServiceID UUID NOT NULL /* this most likely references a location, we will need to find this:
                                     REFERENCES ORGANIZATIONS(OrgID) | REFERENCES PROVIDERS(ProviderID) */,
    ProcCode SMALLINT,
    DiagnosisRef1 BOOLEAN, -- since all of these are either a numeric or null, these are really just flags vv*5
    DiagnosisRef2 BOOLEAN,
    DiagnosisRef3 BOOLEAN,
    DiagnosisRef4 BOOLEAN,
    Units BOOLEAN,
    DeptID SMALLINT,
    NoteID SMALLINT,
    NoteDetailID SMALLINT,
    UnitAmount FLOAT,
    TransferOutID INT,
    TransferTypeID INT,
    Payments FLOAT,
    -- Adjustments FLOAT,
    Transfers FLOAT,
    Outstanding FLOAT,
    AppointmentID UUID NOT NULL REFERENCES CLAIMS(AppointmentID) ON DELETE CASCADE,
    -- LineNoteID INT,
    PatientInsuranceID UUID /*REFERENCES PAYERS(PayerID)*/,
    FeeScheduleID BOOLEAN,
    ProviderID UUID NOT NULL REFERENCES PROVIDERS(ProviderID) ON DELETE CASCADE,
    SupervisingProviderID UUID NOT NULL REFERENCES PROVIDERS(ProviderID) ON DELETE CASCADE
    /*
    I went back and forth on these last two since it is less of an issue to keep HCP data. However,
    since the lens of this project is to look at claims joruney's across prov/orgs/locations, we will assume
    the hypothetical stakeholder only wants data relevant where we can see the full picture and
    will cascade on delete.
    */
);

-- 8.
CREATE TABLE PAYERTRANSITIONS (
    PatientID UUID NOT NULL REFERENCES PATIENTS(PatientID) ON DELETE SET NULL,
    MemberID UUID NOT NULL /*REFERENCES PAYERS(PatientID)?? ON DELETE CASCADE*/,
    StartYear TIMESTAMP,
    EndYear TIMESTAMP,
    PrimPayerID UUID NOT NULL REFERENCES PAYERS(PayerID),
    SecPayerID UUID NOT NULL REFERENCES PAYERS(PayerID),
    /*
    No cascade on delete! Payer info is important for us and seeing where it comes from is important... BUTTTT
    identifying willing-payer opportunities does not necessarily need the org. 
    We will handle this by creating an 'Unidentified Payer' bucket
    */
    OwnershipID INT,
    OwnerNameID INT
);

-- 9.
CREATE TABLE CAREPLAN_REASONCODES (
    CareplanCode BIGINT NOT NULL,
    [Description] TEXT,
    ParenthesesDetail TEXT, 
    PRIMARY KEY (CareplanCode,[Description])
);

CREATE TABLE CAREPLANS (
    CareplanID UUID NOT NULL PRIMARY KEY,
    [Start] TIMESTAMP,
    [End] TIMESTAMP,
    PatientID UUID NOT NULL REFERENCES PATIENTS(PatientID) ON DELETE CASCADE
    EncounterID UUID NOT NULL REFERENCES ENCOUNTERS(EncounterID) ON DELETE SET NULL
    CareplanCode BIGINT NOT NULL REFERENCES CAREPLAN_CODES(CareplanCode),
    CareplanReasonCode BIGINT NOT NULL REFERENCES CAREPLAN_REASONCODES(CareplanReasonCode)
);

-- 10.
CREATE TABLE PROCEDURES_REASONCODES (
    ReasonCode FLOAT ,
    ReasonDescription TEXT,
    ParenthesesDetailDetail TEXT
)

CREATE TABLE PROCEDURES (
    [Start] TIMESTAMP,
    [End] TIMESTAMP,
    [PatientID] UUID NOT NULL REFERENCES PATIENTS(PatientID) ON DELETE CASCADE,
    EncounterID UUID NOT NULL REFERENCES ENCOUNTERS(EncounterID) ON DELETE SET NULL,
    ProcCode FLOAT NOT NULL,
    [Description] TEXT,
    BaseCost FLOAT NOT NULL,
    ReasonCode FLOAT NOT NULL
);

-- 11.
CREATE TABLE OBSERVATIONS (
    
);

-- 12.
CREATE TABLE MEDICATIONS (
    
);

-- 13.
CREATE TABLE IMMUNIZATIONS (
    
);

-- 14.
CREATE TABLE CONDITIONS (
    PatientID UUID NOT NULL REFERENCES PATIENTS(PatientID) ON DELETE SET NULL,
    [Start] TIMESTAMP,
    [Stop] TIMESTAMP,
    EncounterID UUID NOT NULL REFERENCES PATIENTS(EncounterID) ON DELETE CASCADE,
    Code INT,
    DescriptionID INT
);

-- 15.
CREATE TABLE IMAGINGSTUDIES (
    
);

-- 16.
CREATE TABLE DEVICES (
    ID SERIAL,
    [Start] TIMESTAMP NULL,
    [Stop] TIMESTAMP NULL,
    PatientID UUID NOT NULL REFERENCES PATIENTS(PatientID) ON DELETE SET NULL, -- determine the hashing technique
    EncounterID UUID NOT NULL REFERENCES ENCOUNTERS(EncounterID) ON DELETE CASCADE,
    Code INT,
    DescriptionID INT,
    DescriptionDetailID INT,
    UDIID INT
);


-- 17.
CREATE TABLE ALLERGIES (
    
);




