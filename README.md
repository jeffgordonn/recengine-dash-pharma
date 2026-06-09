# Welcome to my Dashboarding Repo
As someone in the pharmaceutical analytics space, I probably should have a dashboarding project somewhere here. We will also incorporate some machine learning once we model the data! This project is a **work in progress**, please forgive some syntaxical issues. My goal is to finish in late July/early August, so if you are plotting a time to revisit here, that would be the time. Else, you can enjoy my brainstoriming

### Motivation
If I could say one particular thing got me interested in data science, it was in my senior year Temple Customer Data Analytics course. Most of the course was very fascinating to me, but segmentation truly made me 'nerd' out. The concept of linear regression on previous behaviors for predicting future behaviors was very natural & I believed this was the secret sauce of how Amazon could predict my behaviors. I quickly learned it was not that simple! But ever since, I have had an affinity for recommendation engines, with one of my first ML models I wrote from scratch being a weighted distance rec engine to compare attorney performance for a previous employeer. I will prefer interpretability / inference over some of the wonderful non-linear methods which have been utilized to enable NN based recommendation engines, perfect for consuming massive, complicated datasets. In this case as well, my data source does not present the same dimensionality concerns which a NN-recommender would salivate to tackle. I am also trying to write basically everything by hand or using former tools, with LLMs only providing a review of existing code or small simple tasks (GSI Extract regex LMAO). I am ***NOT*** against LLMs, I just believe an academic display of skill is best oriented around your conceptual grasp rather than conceptual orientation. 

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
### Ensemble Similarity Score - Bayesian Informed Ensemble of weighted L1, L2, Cosine distance 
By creating an ideal patient, or multiple personas in reality, we can create a ranked list of the best serving HCPs via claims data for the patient. This will not only be able to weight the symptoms and service, but also the payer coverage. With market access being such a hot topic, such a combined logic is necessary. This is where the bayesian component will come in. 

#### HCP Bayesian Informants
The main goal of any pharmaceutical company is, unfortunately, fudicary duty. However, this does not mean we cannot inform our decisions to be guided by patient UX breadcrumbs that we can then therefore assert that our algorithms are 'patient-focused'. Prior strength will determine how strong you want to signal this claim.

#### Spectral Clustering
Discussing with someone about bayes, I was actually informed my problem has a lot of qualities ripe for spectral clustering. Upon informing myself of the conceptual fundamentals, it makes a lot of sense. Consider how HCPs can be well connected by geographically unclose, could be connected on LinkedIn but may not be actively communicating publically, and other details that needs to look at connectivity. In a certain sense, we almost want to create a HCP facebook, DocBook.

#### Similarity Functions for Scoring
Yes, I understand there might be other options to go to but I think this will provide an interpretable and strong baseline for creating a claims based targeting recommender. I also under pgvector could be used here, but this is supposed to be a project showing my competency... I will use it as a comparator tho, despite it probably going to blow mine away in speed.

### What are we targeting?
Well, we will select a few personas to create patient baselines and match these to their best resulting HCPs.
