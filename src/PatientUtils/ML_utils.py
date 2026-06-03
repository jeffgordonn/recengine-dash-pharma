###### Feature Explorations
from sklearn.inspection import permutation_importance
from sklearn.preprocessing import LabelEncoder
from sklearn.decomposition import PCA
from sklearn.model_selection import train_test_split 
from sklearn.model_selection import GridSearchCV
from sklearn.linear_model import LinearRegression # L1, L2 for LASSO, Ridge
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import DBSCAN, KMeans, FeatureAgglomeration, AgglomerativeClustering
from sklearn.metrics import silhouette_score, calinski_harabasz_score, davies_bouldin_score
from scipy.cluster.hierarchy import sch
import scipy.stats
import visualization_utils as visz
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import warnings

# might want to put this into a class at some point
# *looks at watch: its not point-oclock bois
warnings.filterwarnings('ignore')

ml_settings = {}
ml_settings.random_state = 42

def standardize(df:pd.DataFrame.column | np.ndarray):
    transform = StandardScaler()
    standardized = transform.fit_transform(df)
    return standardized

def stringsToID(df:pd.DataFrame | np.ndarray):
    if isinstance(df, pd.DataFrame):
        axis = df.select_dtypes(include=['string','object']).columns
        le = LabelEncoder()
        idcols = []
        for ax in axis:
            idcols.append(f'{str(ax)}_ID')
        df[idcols] = df[axis].apply(lambda x: le.fit_transform(x))
        return df
    else:
        pass # implement the dict-ID process from DL.ai, only need ID-to-String, String-To-ID parts (i think)

#### train test-split
def trainTestSplit(
        targ_at_end:bool=True, stringsToID:bool = True,
        df:pd.DataFrame | None = None, y:pd.column | np.ndarray | None = None,
        include_validation: None | dict = {'trainsplt':0.70,'testsplt':0.2}, **kwargs
):
    '''
    If the target is at the end, only need to provide df. If somewhere else or multi-column output, specify here
    
    Designed
    '''
    if stringsToID:
        for col in df.select_dtypes(include=['String','Object']).columns:
            df[col] = stringsToID(df[col])
    else:
        df = df.select_dtypes(include=['numeric'])
    # most training sets do this and typically I would recommend for organizationally but whatever is your preference
    if targ_at_end:
        # everything up to the last column
        X = df.iloc[:,:-1]
        # last call
        Y = df.iloc[:,-1]
        X_st = standardize(X)
    else:
        X = df.drop(columns=[y])
        Y = y
        X_st = standardize(X)
    if include_validation:
        # to create validation set, let's simply cut the test into smaller portions
        # A typical split for a sufficiently large dataset would be something like 60-30-10 or maybe 70-20-10.
        X_train, X_tobesplit, Y_train, Y_tobesplit = train_test_split(
            X_st, Y, 
            random_state=ml_settings.random_state, 
            test_size=include_validation.trainsplt, **kwargs
        )
        # based on the train-test split, we need to create the portion for the val-test split
        valid_split = include_validation.testsplt/(1-include_validation.trainsplt)
        X_valid, X_test, Y_valid, Y_test = train_test_split(
            X_tobesplit,Y_tobesplit, 
            random_state=ml_settings.random_state,
            test_size=valid_split ,**kwargs
        )
        return X_train, X_valid, X_test, Y_train, Y_valid, Y_test
    else
        X_train, X_test, Y_train, Y_test = train_test_split(X_st, Y, random_state=ml_settings.random_state, **kwargs)
        return X_train, X_test, Y_train, Y_test
#### PCA
def performPCA(X:pd.DataFrame | np.ndarray, feature_columns:list[str], reduce_to_n_dim:int=3):
    '''This is intended to be used post tts split, and will hence be normalized. That is why this will not be included here'''
    # set PCA object
    pca = PCA(n=reduce_to_n_dim)
    pca_details = {}
    feature_details = {}
    pca_data = pca.fit_transform(X)
    pca_details['n'] = (reduce_to_n_dim)
    pca_details['model'] = pca_data
    pca_details['variance'] = pca_data.explained_variance_ratio_.sum()
    feature_details['n'] = (reduce_to_n_dim)
    feature_details['features'] = feature_columns
    abs_feature_values = np.abs(pca_data.components_).sum(axis=0)
    feature_details['values'] = abs_feature_values / abs_feature_values.sum()
    return pca_details, feature_details

def visualizaPCAVarianceLoss(pca_data:pd.DataFrame | np.ndarray):
    pass # need to think how to do this from a non-df perspective

#### LR: Ridge and Lasso
def linearRegressionCV(
        X:np.ndarray, Y:np.ndarray, numeric_features:list[str], 
        grid_params:dict, penalty:str | None = 'l1', cv:int=8, display_output:bool=True
):
    # create object
    lr = LinearRegression()
    # make sure that there was not an error between these and set based off `InitiateGridSearch` activation
    if penalty:
        grid_params.penalty = penalty # LR or Ridge
    else:
        # no normalization penalty used, ensure nothing was passed in the grid_params dict
        grid_params.pop(penalty,None)
    gsCV = GridSearchCV(lr,grid_params,cv=cv)
    gsCV.fit(X,Y)
    # best model based on the results
    best_model = gsCV.best_estimator_
    coefs = pd.Series(best_model.coef_[0],index=numeric_features)
    if penalty == 'l1':
        features = coefs[coefs != 0].sort_values()
    elif penalty == 'l2':
                        # absolute value
        features = coefs[coefs.abs() > 0.05].sort_values()
    else:
        features = coefs.sort_values()
    if display_output:
        with pd.option_context('display.max_rows', None):
            print(features)

    return gsCV, best_model, coefs, features

def InitiateGridSearch(
        model_type:str='LASSO', **kwargs
):
    if model_type == 'LASSO':
        linearRegressionCV(penalty='l1',**kwargs)
    elif model_type == 'RIDGE':
        linearRegressionCV(penalty='l1',**kwargs)
    elif model_type == 'LINEAR':
        linearRegressionCV(penalty=None,**kwargs)
    else:
        pass

## permutations
# results of Ridge and LASSO
def visualizePermutations(
        df:pd.DataFrame,array:np.array,title:str='Permuation Importances',
        fig_wd:int=20,fig_ht:int=25, tight_layout:bool=False
):
    # sort array on mean value
    sorted_idx = array.importances_mean.argsort()
    # visualize the feature importances
    fig, ax = plt.subplots()
    fig.set_figwidth(fig_wd) 
    fig.set_figheight(fig_ht)
    if tight_layout:
        fig.tight_layout()
    ax.boxplot(
        array.importances[sorted_idx].T,
        vert=False, labels=df.iloc[:,:-1].columns[sorted_idx]
    )
    ax.set_title(title)
    plt.show()

def checkPermutations(x_train: np.ndarray, y_train:np.ndarray, model:GridSearchCV, display_text:bool=False, **kwargs):
    '''
    `model` is from a gridsearch cross validation object. Let's use a specified model because while we will probably want
    to evaluate the best result, we will also want to check the other top models and see what kind of agreement we see
    '''
    feature_importances = permutation_importance(estimator=model, x=x_train,y=y_train, **kwargs)
    if display_text:
        # Reindicate the size of the columns / analysis
        print(feature_importances.importances.shape)
        # display the feature importance data textually
        print(feature_importances.importances)
    visualizePermutations(feature_importances)

def kmeansClustering(X:np.ndarray, lb:int=2, ub:int=10):
    global ml_settings
    inertia = {}
    for n in range(lb,ub+1):
        km = KMeans(n_clusters=n,random_state=ml_settings.random_state)
        # for 17 pc
        km.fit(X)
        labels = km.labels_
        X = X.hstack(labels) # add these as a part of the array, need to add to self so no override loss
        # for elbow plot
        inertia[n] = km.inertia_
    return X, inertia
    
def wardHierarchalClustering(X:np.ndarray, lb:int=2 , ub:int=10):
    for n in (lb,ub+1):
        ward = AgglomerativeClustering(n_clusters=n, linkage='ward')
        labels = ward.fit_predict(X)
        X = X.hstack(labels)
    return X

def agglomHierarchalClustering(X:np.ndarray, link_method:str='average', lb:int=2 , ub:int=10):
    for n in (lb,ub+1):
        agc = AgglomerativeClustering(n_clusters=n, linkage='ward')
        labels = agc.fit_predict(X)
        X = X.hstack(labels)
    return X

def dbscanClustering(X:np.ndarray, lb:int=2 , ub:int=10, incrament:float=0.1):
    dbscan_results = {}
    for e in np.arange(lb,ub,incrament):
        for mn in range():
            dbs = DBSCAN(eps=e,min_samples=mn)
            dbs.fit_predict(X)
            n_noise = np.sum(dbs.labels_ == -1)
            n_clusters = len(set(dbs.labels_)) - (1 if -1 in dbs.labels_ else 0)
            # scores need more than one cluster
            if n_clusters <= 1:
                continue
            # for dataframe
            dbscan_results['silhouette_avg'] = silhouette_score(X, dbs.labels_)
            dbscan_results['ch_score'] = calinski_harabasz_score(X, dbs.labels_)
            dbscan_results['db_score'] = davies_bouldin_score(X, dbs.labels_)
# dbs_eval = dbs_pca17_results[
#     ((dbs_pca17_results["Silhouette_Score"] > 0.4) & 
#     (dbs_pca17_results["DavBoi_Score"] < 1.3))
# ]
# dbs_eval = dbs_eval.sort_values(by="DavBoi_Score",ascending=True)
# print(len(dbs_eval))
# with pd.option_context('display.max_rows', None):
#     print(dbs_eval[:100])

def performClustering(X, method:str='kmeans', **kwargs):
    if (method.lower() == 'kmeans') or (method.lower() == 'km'):
        return kmeansClustering(X, **kwargs)
    elif (method.lower() == 'ward'):
        return wardHierarchalClustering(X, **kwargs)
    elif 'agglom' in method.lower():
        return agglomHierarchalClustering(X, **kwargs)
    elif method.lower() == 'dbscan':
        return dbscanClustering(X, **kwargs)
    else:
        raise ValueError("method must be: ['kmeans','hierarchal','dbscan']")
    
# hierarchal clustering but with the desire to see how closely related features
# this is for higher dimensions like a photo but was reading the sklearn docs and noticed this
# might be nice to use later
def featureAggloms(X:np.ndarray,n:int,**kwargs):
    featGloms = FeatureAgglomeration(n_clusters=n)
    featGloms.fit(X)
    X_reduced = featGloms.transform(X)
    return X_reduced

# Autocovariance? -- prolly not sicne its synth data. Some other bayesian method?
# anything else?