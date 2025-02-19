#' @title estimate_popsize
#'
#' @param data Data frame for the regression
#' @param formula Description of model to that is supposed to be fitted
#' @param model Model for regression and population estimate
#' @param weights Optional object of a-priori weights used in fitting the model
#' @param subset Same as in glm
#' @param na.action TODO
#' @param method Method for fitting values currently supported IRLS and MaxLikelihood
#' @param pop.var A method of constructing confidence interval either analytic or bootstrap
#' where bootstraped confidence interval may either be based on 2.5%-97.5%
#' percientiles ("bootstrapPerc") or studentized CI ("bootstrapSD")
#' @param control.method ||
#' @param control.model ||
#' @param control.pop.var A list indicating parameter to use in population size variance estimation
#' @param model.matrix If true returns model matrix as a part of returned object
#' @param x manually provided model matrix
#' @param y manually provided vector for dependent variable
#' @param contrasts ||
#' @param ... Arguments to be passed to other methods
#'
#' @return Returns an object of classes inherited from glm containing:\cr
#' @returns
#' \itemize{
#'  \item{y argument of observations}
#'  \item{formula provided on call}
#'  \item{call on which model is based}
#'  \item{coefficients a vector of fitted coefficients of regression}
#'  \item{standard_errors SE of fitted coefficients of regression}
#'  \item{wValues test values for Wald test}
#'  \item{pValues P values for Wald test}
#'  \item{null.deviance TODO}
#'  \item{model on which estimation and regression was built}
#'  \item{aic akaike information criterion}
#'  \item{bic bayesian information criterion}
#'  \item{deviance TODO}
#'  \item{prior.weight weight provided on call}
#'  \item{weights if robust method of estimation was chosen, weights returned by IRLS}
#'  \item{residuals working residuals}
#'  \item{logL logarithm likelihood obtained}
#'  \item{iter numbers of iterations performed in fitting}
#'  \item{dispersion dispersion parameter if applies}
#'  \item{df.residuals residual degrees of freedom}
#'  \item{df.null null degrees of freedom}
#'  \item{fitt.values vector of fitted values}
#'  \item{populationSize a list containing information of population size estimate}
#'  \item{linear predictors vector of linear predictors}
#'  \item{qr qr decomposision of model matrix, might be removed later since it's
#'  not used anywhere in package}
#' }
#'
#' @importFrom stats glm.fit
#' @importFrom stats poisson
#' @importFrom stats model.frame
#' @importFrom stats model.matrix
#' @importFrom stats optim
#' @importFrom MASS glm.nb
#' @importFrom stats pnorm
#' @export
estimate_popsize <- function(formula,
                             data,
                             model = c("ztpoisson", "ztnegbin",
                                       "zotpoisson", "zotnegbin",
                                       "zelterman", "chao",
                                       "ztgeom", "zotgeom"),
                             weights = 1,
                             subset = NULL,
                             na.action = NULL,
                             method = c("mle", "robust"),
                             pop.var = c("analytic",
                                         "bootstrap"),
                             control.method = NULL,
                             control.model = NULL,
                             control.pop.var = NULL,
                             model.matrix = TRUE,
                             x = FALSE,
                             y = FALSE,
                             contrasts = NULL,
                             ...) {
  subset <- parse(text = deparse(substitute(subset)))
  if (!is.data.frame(data)) {
    data <- data.frame(data)
  }
  # adding control parameters that may possibly be missing
  m1 <- control.pop.var
  m2 <- control.pop.var()
  m2 <- m2[names(m2) %in% names(m1) == FALSE]
  control.pop.var <- m2
  m1 <- control.method
  m2 <- control.method()
  m2 <- m2[names(m2) %in% names(m1) == FALSE]
  control.method <- m2
  m1 <- control.model
  m2 <- control.model()
  m2 <- m2[names(m2) %in% names(m1) == FALSE]
  control.model <- m2
  typefitt <- control.model$typefitted
  typefitt <- ifelse(is.null(typefitt), "link", typefitt)
  family <- model
  dispersion <- NULL
  if (is.character(family)) {
    family <- get(family, mode = "function", envir = parent.frame())
  }
  if (is.function(family)) {
    family <- family()
  }
  trcount <- ifelse(is.null(control.pop.var$trcount), 0,
                    control.pop.var$trcount)

  model_frame <- stats::model.frame(formula, data,  ...)
  variables <- stats::model.matrix(formula, model_frame, ...)
  subset <- eval(subset, model_frame)
  if (is.null(subset)) {subset <- TRUE}
  # subset is often in conflict with some packages hence explicit call
  model_frame <- base::subset(model_frame, subset = subset)
  if (isFALSE(x)) {
    variables <- base::subset(variables, subset = subset)
  } else {
    variables <- x
  }
  if (isFALSE(y)) {
    observed <- model_frame[, 1]
  } else {
    observed <- y
  }
  
  if(sum(observed == 0) > 0) {
    stop("Error in function estimate.popsize, data contains zero-counts")
  }

  if (!family$valideta(start) && !is.null(start)) {
    stop("Invalid start parameter")
  }

  if (!is.null(weights)) {
    prior.weights <- as.numeric(weights)
  } else {
    prior.weights <- 1
  }
  weights <- 1

  if (family$family %in% c("zotpoisson", "zotnegbin", "zotgeom") &&
      1 %in% unique(observed)) {
    cat("One counts detected in two truncated model.",
        "In this model of estimation only counts =>2 are used.",
        "One counts will be deleted and their number added to trcount",
        sep = "\n")

    tempdata <- data.frame(observed, prior.weights, variables)
    trcount <- trcount + length(observed[observed == 1])
    tempdata <- tempdata[tempdata["observed"] > 1, ]

    observed <- tempdata[, 1]
    prior.weights <- tempdata[, 2]
    
    n1 <- colnames(variables)
    variables <- data.frame(tempdata[, -c(1, 2)])
    colnames(variables) <- n1
  } else if (family$family == "chao" &&
             !(all(as.numeric(names(table(observed))) %in% c(1, 2)))) {
    cat("Counts > 2 detected in chao model.
        In this model of estimation only counts 1 and 2 are used.",
        "Counts 3 4 5 .... will be deleted and their number added to trcount",
        sep = "\n")

    tempdata <- data.frame(observed, prior.weights, variables)
    trcount <- trcount + length(observed[observed > 2])
    tempdata <- tempdata[tempdata["observed"] == 1 | tempdata["observed"] == 2, ]

    observed <- tempdata[, 1]
    prior.weights <- tempdata[, 2]
    n1 <- colnames(variables)
    variables <- data.frame(tempdata[, -c(1, 2)])
    colnames(variables) <- n1
  }

  n1 <- colnames(variables)
  
  if (family$family == "zelterman") {
    # In zelterman model regression is indeed based only on 1 and 2 counts
    # but estimation is based on ALL counts
    name1 <- "observed"
    n1 <- colnames(variables)
    tempdata <- data.frame(observed, prior.weights, variables)
    tempdata <- tempdata[tempdata[name1] == 1 | tempdata[name1] == 2, ]

    if ((dim(variables)[2] == 1) && ("(Intercept)" %in% colnames(variables))) {
      tempobserved <- tempdata[, 1]
      tempvariables <- data.frame("(Intercept)" = rep(1, length(tempobserved)))
      prior.weightstemp <- tempdata[, 2]
    } else {
      tempobserved <- tempdata[, 1]
      prior.weightstemp <- tempdata[, 2]
      tempvariables <- as.matrix(tempdata[, -c(1, 2)])
    }
    colnames(tempvariables) <- n1
  } else {
    tempobserved <- observed
    tempvariables <- variables
    prior.weightstemp <- prior.weights
  }
  

  if(colnames(tempvariables)[1] == "X.Intercept.") {
    colnames(tempvariables)[1] <- "(Intercept)"
    colnames(variables)[1] <- "(Intercept)"
  }

  if (family$family %in% c("ztpoisson", "zotpoisson",
                           "chao", "zelterman",
                           "ztgeom", "zotgeom")) {
    start <- stats::glm.fit(x = variables,
                            y = observed,
                            family = stats::poisson())$coefficients
    if (family$family %in% c("chao", "zelterman")) {
      start[1] <- start[1] + log(1 / 2)
    }
  } else {
    #start <- MASS::glm.nb(formula = formula, data = data)
    #dispersion <- -start$theta
    #start <- start$coefficients
    start <- stats::glm.fit(x = variables,
                            y = observed,
                            family = stats::poisson())$coefficients
    dispersion <- log(abs(mean(observed ** 2) - mean(observed)) / (mean(observed) ** 2))
  }

  FITT <- estimate_popsize.fit(y = tempobserved,
                               X = tempvariables,
                               family = family,
                               control = control.method,
                               method,
                               prior.weights = prior.weightstemp,
                               start = c(dispersion, start),
                               dispersion = dispersion,
                               ...)
  eta <- FITT$eta
  coefficients <- FITT$beta

  log_like <- FITT$ll
  grad <- FITT$grad
  hessian <- FITT$hessian

  hess <- FITT$hess
  iter <- FITT$iter
  df.reduced <- FITT$degf
  weights <- FITT$weights

  if (is.null(dispersion)) {
    eta <- as.matrix(variables) %*% coefficients
  } else {
    eta <- as.matrix(variables) %*% coefficients[-1]
  }

  parameter <- family$linkinv(eta)
  if (typefitt == "link") {
    fitt <- family$linkinv(eta)
  } else if (typefitt == "mu") {
    fitt <- family$mu.eta(eta = eta, disp = dispersion)
  }

  if (!is.null(dispersion)) {
    dispersion <- coefficients[1]
  }

  if (sum(diag(-solve(hess)) <= 0) != 0) {
    stop("fitting error analytic hessian is invalid,
         try another model")
  } else {
    stdErr <- sqrt(diag(solve(-hess)))
  }
  wVal <- coefficients / stdErr

  null.deviance <- as.numeric(NULL)
  LOG <- -log_like(coefficients)
  resRes <- prior.weights * (observed - fitt)
  aic <- 2 * length(coefficients) - 2 * LOG
  bic <- length(coefficients) * log(length(observed)) - 2 * LOG
  deviance <- as.numeric(NULL)
  # In wald W-values have N(0,1) distributions (asymptotically)
  pVals <- (stats::pnorm(q =  abs(wVal), lower.tail = FALSE) +
            stats::pnorm(q = -abs(wVal), lower.tail = TRUE))
  qr <- qr(variables)

  POP <- populationEstimate(y = observed,
                            X = as.data.frame(variables),
                            grad = grad,
                            hessian = hessian,
                            method = pop.var,
                            weights = prior.weights,
                            parameter = parameter,
                            family = family,
                            dispersion = dispersion,
                            beta = coefficients,
                            control = control.pop.var)

  result <- list(y = observed,
                 X = as.data.frame(variables),
                 formula = formula,
                 call = match.call(),
                 coefficients = coefficients,
                 standard_errors = stdErr,
                 wValues = wVal,
                 pValues = pVals,
                 null.deviance = null.deviance,
                 model = family,
                 aic = aic,
                 bic = bic,
                 deviance = deviance,
                 prior.weights = prior.weights,
                 weights = weights,
                 residuals = resRes,
                 logL = LOG,
                 iter = iter,
                 dispersion = dispersion,
                 df.residual = df.reduced,
                 df.null = length(observed) - 1,
                 fitt.values = fitt,
                 populationSize = POP,
                 model = model_frame,
                 linear.predictors = eta,
                 qr = qr,
                 rank = qr$rank,
                 trcount = trcount)
  class(result) <- c("singleR", "glm", "lm")
  result
}
