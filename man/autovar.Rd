% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/autovar.r
\name{autovar}
\alias{autovar}
\title{Return the best VAR models found for a time series data set}
\usage{
autovar(raw_dataframe, selected_column_names, significance_levels = c(0.05,
  0.01, 0.005), test_names = c("portmanteau", "portmanteau_squared",
  "skewness"), criterion = "BIC", imputation_iterations = 100,
  measurements_per_day = 1)
}
\arguments{
\item{raw_dataframe}{The raw, unimputed data frame. This can include columns other than the \code{selected_column_names}, as those may be helpful for the imputation. The measurements in the dataframe are expected to be sorted by time, and to be sequential. Missed measurements should be encoded as rows of \code{NA} values and will be imputed by EM imputation.}

\item{selected_column_names}{The endogenous variables in the models, specified as a vector of character strings. This argument is required. The selected column names should be a subset of the column names of \code{raw_dataframe}.}

\item{significance_levels}{The significance levels used for evaluating the significance of the residual tests. The variable \code{significance_levels} is a vector with descending p values that indicate cut-offs placing models in different buckets. If it is not specified, this parameter defaults to \code{c(0.05, 0.01, 0.005)}. More, fewer, and/or different significance levels can be specified. In practice, specifying more significance levels gives more weight to the outcomes of the residual tests, while having fewer significance levels gives more weight to the AIC/BIC scores and the number of dummy variables. If a test for a model has a lower p-level than the minimum specified significance level, it can still be returned by the program, but it will be assigned the special significance bucket \code{0}.}

\item{test_names}{The residual tests that should be performed, specified as a vector of character strings. If not specified, this parameter defaults to \code{c('portmanteau', 'portmanteau_squared', 'skewness')}, which are used to test the assumptions of independence, homoscedasticity, and normality, respectively. The possible tests are \code{c('portmanteau', 'portmanteau_squared', 'skewness', 'kurtosis', 'joint_sktest')}. In addition to the residual tests, please note that the Eigenvalue stability test is always performed.}

\item{criterion}{The information criterion used to sort the models. Valid options are 'BIC' (the default) or 'AIC'.}

\item{imputation_iterations}{The amount of times the Amelia imputation should be averaged over. The default value for this parameter is \code{100}. For details on the Amelia imputation, please see \url{http://r.iq.harvard.edu/docs/amelia/amelia.pdf}.}

\item{measurements_per_day}{The number of measurements per day in the time series data. The default value for this parameter is \code{1}. All models considered include day-part dummy variables if there are multiple measurements per day. If this value is \code{0}, then daypart- and weekday dummies variables are not included for any models.}
}
\value{
A sorted list of the best models found. A "model" is a list with the properties \code{logtransformed}, \code{lag}, \code{varest}, \code{model_score}, \code{bucket}, and \code{nr_dummy_variables}. The number of models returned is at most four. In rare cases, where the Eigenvalue stability test fails for multiple models, a list with fewer than four models is returned. When the Eigenvalue test fails for all tested models (which is unlikely to happen in practice), an empty \code{list()} is returned.
}
\description{
This function evaluates possible VAR models for the given time series data set and returns a sorted list of the best models found. The first item in this list is the "best model" found.
}
\details{
AutovarCore evaluates eight kinds of VAR models: models with and without log transforming the data, lag 1 and lag 2 models, and with and without weekday dummy variables. For the lag 2 models, all cross-lagged relations are constrained. For each of these 8 model configurations, we evaluate all possible combinations for including outlier dummies (at 2.5x the standard deviation of the residuals) and retain the best model (the procedure for selecting the best model is described in more detail below).

These eight models are further reduced to four models by determining whether adding weekday dummies improves the model fit. AutovarCore does so based first on the significance bucket (determined by the outcomes of the residual tests) and secondly on the AIC/BIC score. If the best model found with weekday dummies is a "better model" than the best model found without weekday dummies, then AutovarCore includes the model with weekday dummies and discards the one without weekday dummies. Otherwise, AutovarCore includes only the model without weekday dummies and discards the one with weekday dummies. Thus, the comparison between models with and without weekday dummies is based on two steps:

\enumerate{
\item We first consider the significance bucket. If the two models being compared are in different significance buckets, AutovarCore chooses the one with the highest significance bucket, and otherwise proceeds to step 2. The significance buckets are formed between each of the (decreasingly sorted) specified \code{significance_levels} in the parameters to the autovar function call. For example, if the \code{signifance_levels} are \code{c(0.05, 0.01, 0.005)}, then the significance buckets are \code{(0.05 <= x)}, \code{(0.01 <= x < 0.05)}, \code{(0.005 <= x < 0.01)}, and \code{(x < 0.005)}. The metric used to place a model into a bucket is the maximum p-level at which all residual tests will still pass ("pass" meaning not invalidating the model assumptions of independence, homoscedasticity, and normality).

\item When the significance bucket for the two models being compared is the same, AutovarCore selects the model with the lowest AIC/BIC score. Whether the AIC or BIC is used here depends on the \code{criterion} option specified in the parameters to the autovar function call.
}

The result of this procedure is four models: models with and without log transforming the data, and lag 1 and lag 2 models. Next, AutovarCore will determine whether the models with lag 1 or the models with lag 2 are best, and sort the models accordingly. This comparison is again based firstly on the significance bucket. If the significance bucket is the same, it proceeds to the next step, which in this case is the number of outlier dummy variables; the model with the fewest outlier dummy variables is considered the best. If the number of outlier dummy variables is the same, it proceeds to the third step, in which AutovarCore prefers the model with the lowest AIC/BIC score. This procedure results in two sorted lists of models, one list with models without logtransformation, one list with models with logtransformation.

In the final step, AutovarCore merges the sorted lists of models with and without logtransformation. To this end, it first compares the best model of the set without logtransformation with the best logtransformed model. It will sort these models based on the significance bucket first and the AIC/BIC score secondly. After finding the best model, it is removed from its list, and the then-best models are compared. This process repeats itself until both lists are empty. The result of this procedure is a final sorted list of four models (with the best model listed first).

The reason for the different sorting algorithms is that in some cases we want to select the model with the fewest outlier dummy columns (i.e., the model that retains most of the original data), while in other cases we know that a certain operation (such as adding weekday dummies or logtransforming the data set) will affect the amount of dummies in the model and so a fair comparison would exclude this property. For example, we do not compare the number of outlier columns in the final step because this would have likely favored logtransformed models over models without logtransform, as logtransformations typically have the effect of reducing the outliers of a sample.

Outliers are, for each variable, the measurements at >2.5 times the standard deviation away from the mean of the residuals or of the squared residuals. Outlier dummy variables are split up such that each time point that is considered an outlier has its own dummy outlier variable and adds one to the count of outlier columns. Checks are in place to ensure that a time point identified as an outlier by multiple variables only adds a single dummy outlier column to the equation. For the count of outlier columns, day-part dummies do not add to the count. This is because when they are included, they are included for each model and thus never have any discriminatory power.

We are able to compare the AIC/BIC scores of logtransformed and nonlogtransformed models fairly because we compensate the AIC/BIC scores to account for the effect of the logtransformation. We compensate for the logtransformation by adjusting the loglikelihood score of the logtransformed models in the calculation of their AIC/BIC scores (by subtracting the sum of the logtransformed data).
}
\examples{
\dontrun{
data_matrix <- matrix(nrow = 40, ncol = 3)
data_matrix[, ] <- runif(ncol(data_matrix) * nrow(data_matrix), 1, nrow(data_matrix))
while (sum(is.na(data_matrix)) == 0)
  data_matrix[as.logical(round(runif(ncol(data_matrix) * nrow(data_matrix), -0.3, 0.7)))] <- NA
colnames(data_matrix) <- c('rumination', 'happiness', 'activity')
dataframe <- as.data.frame(data_matrix)
autovar(dataframe, selected_column_names = c('rumination', 'happiness'),
                   significance_levels = c(0.05, 0.01, 0.005),
                   test_names = c('portmanteau',
                                  'portmanteau_squared',
                                  'skewness'),
                   criterion = 'AIC',
                   imputation_iterations = 100,
                   measurements_per_day = 1)
}
}
