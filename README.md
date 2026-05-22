# Welcome to my Dashboarding Repo
As someone in the pharmaceutical analytics space, I probably should have a dashboarding project somewhere here.

### Motivation
If I could say one particular thing got me interested in data science, it was in my senior year Temple Customer Data Analytics course. Most of the course was very fascinating to me, but segmentation truly made me 'nerd' out. The concept of linear regression on previous behaviors for predicting future behaviors not just 

## Data Source
[Synthetic Dataset from SyntheticMass](https://synthea.mitre.org/downloads)

I choose the 1K Sample Synthetic Patient Records.csv 

## Phase 1 - Analytics Dashboarding
### Database Modelling
This will be a primarily STAR schema, with integer mapping for the repetitive string data for speed reasons. This will be modelling an analytics reporting workflow so a classical STAR schema from a business warehouse is sensible here. 

### `ON DELETE` Choices for FKs
Delete on cascade is used on the following levels across fact tables. 
> Please be mindful ALL detail tables will cascade upon deletion of the master record
- Patients - `SET NULL`
    * To segment HCPs based on the data we have (snythetic), to spot our primo-topline drug influencer, we need to understand their distribution behaviors. While keeping a full profile for patients is ideal, the HCPs/organizations serving them can still have behaviors identified with `NULL` patient IDs
- Encounters - `CASCADE`
    * Encounters make less sense to track if they are deleted because we cannot get insights from them. An unidentified patientID does take away the encounter's details but we can only get monetary insights from the claimn if a encounter is deleted from the master
- Providers - `CASCADE`
    * Visibility into their purchasing behaviors & expertise would be essential for an analytics workflow which is trying to establish ideal HCPs segmentations
- Claims, Claims Transactions  - `CASCADE`
    * To establish which HCPs/Organizations serve our target audience, we need insight into their claims, ideally end to end service but there is not point in maintaining details regarding claims if there is nothing to associate

## Phase 2 - Segmentation Strategies
### Ensemble Similarity Score - Weighted L1, L2, Cosine distance
By creating an ideal patient, or multiple personas in reality, we can create a ranked list of the best serving HCPs via claims data for the patient. This will not only be able to weight the symptoms and service, but also the payer coverage. With market access being such a hot topic, such a combined logic is necessary

### What are we targeting?
