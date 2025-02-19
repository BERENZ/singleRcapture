% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SingleRmodel.R
\name{estimate_popsize}
\alias{estimate_popsize}
\title{estimate_popsize}
\usage{
estimate_popsize(
  formula,
  data,
  model = c("ztpoisson", "ztnegbin", "zotpoisson", "zotnegbin", "zelterman", "chao",
    "ztgeom", "zotgeom"),
  weights = 1,
  subset = NULL,
  na.action = NULL,
  method = c("mle", "robust"),
  pop.var = c("analytic", "bootstrap"),
  control.method = NULL,
  control.model = NULL,
  control.pop.var = NULL,
  model.matrix = TRUE,
  x = FALSE,
  y = FALSE,
  contrasts = NULL,
  ...
)
}
\arguments{
\item{formula}{Description of model to that is supposed to be fitted}

\item{data}{Data frame for the regression}

\item{model}{Model for regression and population estimate}

\item{weights}{Optional object of a-priori weights used in fitting the model}

\item{subset}{Same as in glm}

\item{na.action}{TODO}

\item{method}{Method for fitting values currently supported IRLS and MaxLikelihood}

\item{pop.var}{A method of constructing confidence interval either analytic or bootstrap
where bootstraped confidence interval may either be based on 2.5\%-97.5\%
percientiles ("bootstrapPerc") or studentized CI ("bootstrapSD")}

\item{control.method}{||}

\item{control.model}{||}

\item{control.pop.var}{A list indicating parameter to use in population size variance estimation}

\item{model.matrix}{If true returns model matrix as a part of returned object}

\item{x}{manually provided model matrix}

\item{y}{manually provided vector for dependent variable}

\item{contrasts}{||}

\item{...}{Arguments to be passed to other methods}
}
\value{
Returns an object of classes inherited from glm containing:\cr

\itemize{
\item{y argument of observations}
\item{formula provided on call}
\item{call on which model is based}
\item{coefficients a vector of fitted coefficients of regression}
\item{standard_errors SE of fitted coefficients of regression}
\item{wValues test values for Wald test}
\item{pValues P values for Wald test}
\item{null.deviance TODO}
\item{model on which estimation and regression was built}
\item{aic akaike information criterion}
\item{bic bayesian information criterion}
\item{deviance TODO}
\item{prior.weight weight provided on call}
\item{weights if robust method of estimation was chosen, weights returned by IRLS}
\item{residuals working residuals}
\item{logL logarithm likelihood obtained}
\item{iter numbers of iterations performed in fitting}
\item{dispersion dispersion parameter if applies}
\item{df.residuals residual degrees of freedom}
\item{df.null null degrees of freedom}
\item{fitt.values vector of fitted values}
\item{populationSize a list containing information of population size estimate}
\item{linear predictors vector of linear predictors}
\item{qr qr decomposision of model matrix, might be removed later since it's
not used anywhere in package}
}
}
\description{
estimate_popsize
}
