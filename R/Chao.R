#' Chao model for the population size estimation
#'
#' @return A object of class "family" containing objects \cr
#' make_minusloglike(y,X) - for creating negative likelihood function \cr
#' make_gradient(y,X) - for creating gradient function \cr
#' make_hessian(X) - for creating hessian \cr
#' linkfun - a link function to connect between linear predictor and model parameter in regression and a name of link function\cr
#' linkinv - an inverse function of link \cr
#' dlink - a 1st derivative of link function \cr
#' mu.eta,variance - Expected Value and variance \cr
#' aic - for aic computation\cr
#' valedmu, valideta - for checking if regression arguments and valid\cr
#' family - family name\cr
#' Where: \cr
#' y is a vector of observed values \cr
#' X is a matrix / data frame of covariates
#' @export
chao <- function() {
  link <- function(x) {log(x / 2)}
  invlink <- function (x) {2 * exp(x)}
  dlink <- function(lambda) {1 / lambda}

  mu.eta <- function(disp = NULL, eta) {
    1 / (1 + exp(-eta))
  }

  variance <- function(disp = NULL, mu) {
    mu * (1 - mu)
  }

  minusLogLike <- function(y, X, weight = 1) {
    y <- as.numeric(y)
    z <- y
    z[z == 1] <- 0
    z[z == 2] <- 1
    if (is.null(weight)) {
      weight <- 1
    }

    function(beta) {
      eta <- as.matrix(X) %*% beta
      lambda <- invlink(eta)
      L1 <- lambda / 2
      -sum(weight * (z * log(L1 / (1 + L1)) + (1 - z) * log(1 / (1 + L1))))
    }
  }

  gradient <- function(y, X, weight = 1) {
    y <- as.numeric(y)
    z <- y
    z[z == 1] <- 0
    z[z == 2] <- 1
    if (is.null(weight)) {
      weight <- 1
    }

    function(beta) {
      eta <- as.matrix(X) %*% beta
      lambda <- invlink(eta)
      L1 <- lambda / 2
      t(X) %*% ((z - L1 / (1 + L1)) * weight)
    }
  }

  hessian <- function(y, X, weight = 1) {
    y <- as.numeric(y)
    z <- y
    z[z == 1] <- 0
    z[z == 2] <- 1
    if (is.null(weight)) {
      weight <- 1
    }

    function(beta) {
      eta <- as.matrix(X) %*% beta
      lambda <- invlink(eta)
      L1 <- lambda / 2
      term <- -(L1 / ((1 + L1) ** 2))
      t(as.data.frame(X) * weight * term) %*% as.matrix(X)
    }
  }

  validmu <- function(mu) {
    (sum(!is.finite(mu)) == 0) && all(1 > mu)
  }

  dev.resids <- function(y, mu, wt, disp = NULL) {
    NULL
  }

  aic <- function(y, mu, wt, dev) {
    z <- y
    z[z == 1] <- 0
    z[z == 2] <- 1
    L1 <- mu / 2
    -2 * -sum((z * log(L1 / (1 + L1)) + (1 - z) * log(1 / (1 + L1))) * wt)
  }

  pointEst <- function (disp = NULL, pw, lambda, contr = FALSE) {
    N <- ((1 + 1 / (lambda + (lambda ** 2) / 2)) * pw)
    if(!contr) {
      N <- sum(N)
    }
    N
  }

  popVar <- function (beta, pw, lambda, disp = NULL, hess, X) {
    X <- as.data.frame(X)
    I <- -hess(beta)
    prob <- lambda * exp(-lambda) + (lambda ** 2) * exp(-lambda) / 2

    f1 <- colSums(-X * pw * ((lambda + (lambda ** 2)) /
                  ((lambda + (lambda ** 2) / 2) ** 2)))
    f1 <- t(f1) %*% solve(as.matrix(I)) %*% f1

    f2 <- sum(pw * (1 - prob) * ((1 + exp(-lambda) / prob) ** 2))

    f1 + f2
  }

  R <- list(make_minusloglike = minusLogLike,
            make_gradient = gradient,
            make_hessian = hessian,
            linkfun = link,
            linkinv = invlink,
            dlink = dlink,
            mu.eta = mu.eta,
            aic = aic,
            link = "log",
            valideta = function (eta) {TRUE},
            variance = variance,
            dev.resids = dev.resids,
            validmu = validmu,
            pointEst = pointEst,
            popVar= popVar,
            family = "chao")
  class(R) <- "family"
  R
}
