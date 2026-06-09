import numpy as np
import pandas as pd
from ..logging import logging_utils

## horseshoe prior for coefficient regularization
## 

class Bayesian:


    def NaiveBayes(
            coef_target:str | None = None,
            prob_weight_dict:dict | None = None
    ):
        total_p = sum(
            var['prior'] for var in prob_weight_dict.values()
        )
        # numerator
        B_a = (
            prob_weight_dict[coef_target]['event_likelihood'] *
            (prob_weight_dict[coef_target]['prior']/total_p)
        )
        # denom
        B = sum(
            var['event_likelihood'] + (var['prior']/total_p)
            for var in prob_weight_dict.values()
        )
        return B_a/B

    def createProbWeightDict(
            population_samples: pd.DataFrame | None = None,
            prior_samples: pd.DataFrame | None = None
    ):
        # assumes same shape on columns
        prob_weight_dict = {
            popcol:{
                'event_likelihood':population_samples[popcol].sum(),
                'prior':prior_samples[pricol].sum()
            }
            for popcol, pricol in zip(
                population_samples.columns, prior_samples.columns
            )
        }
        return prob_weight_dict

    def calculateLikelihood():
        pass

    def updatePrior():
        pass
        
