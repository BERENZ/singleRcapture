#' Zero-one truncated Poisson model
#'
#' @return A object of class "family" containing objects \cr
#' make_minusloglike(y,X) - for creating negative likelihood function \cr
#' make_gradient(y,X) - for creating gradient function \cr
#' make_hessian(X) - for creating hessian \cr
#' linkfun - a link function to connect between linear predictor and model parameter in regression and a name of link function\cr
#' linkinv - an inverse function of link \cr
#' Dlink - a 1st derivative of link function \cr
#' mu.eta,Variance - Expected Value and Variance \cr
#' aic - for aic computation\cr
#' valedmu, valideta - for checking if regression arguments and valid\cr
#' family - family name\cr
#' Where: \cr
#' y is a vector of observed values \cr
#' X is a matrix / data frame of covariates
#' @export
zotpoisson <- function() {
  link <- log
  invlink <- exp
  dlink <- function(lambda) {
    1 / lambda
  }

  mu.eta <- function(disp = NULL, eta) {
    lambda <- invlink(eta)
    (lambda - lambda * exp(-lambda)) / (1 - exp(-lambda) - lambda * exp(-lambda))
  }

  variance <- function(disp = NULL, mu) {
    mu
  }

  minusLogLike <- function(y, X, weight = 1) {
    y <- as.numeric(y)
    if (is.null(weight)) {
      weight <- 1
    }

    function(beta) {
      eta <- as.matrix(X) %*% beta
      lambda <- exp(eta)
      -sum(weight * (y * eta - lambda - log(factorial(y)) -
           log(1 - exp(-lambda) - lambda * exp(-lambda))))
    }
  }

  gradient <- function(y, X, weight = 1) {
    y <- as.numeric(y)
    if (is.null(weight)) {
      weight <- 1
    }
    function(beta) {
      lambda <- exp(as.matrix(X) %*% beta)
      term <- lambda / (exp(lambda) - lambda - 1)

      t(as.matrix(X)) %*% (weight * (y - lambda - lambda * term))
    }
  }

  hessian <- function(y, X, weight = 1) {
    X <- as.matrix(X)
    y <- as.numeric(y)

    if (is.null(weight)) {
      weight <- 1
    }

    function(beta) {
      lambda <- exp(as.matrix(X) %*% beta)

      term <- (((2 + lambda ** 2) * exp(lambda) - exp(2 * lambda) - 1) /
                ((exp(lambda) - lambda - 1) ** 2))

      hes <- t(X) %*% as.matrix(t(t(as.data.frame(X) * lambda * term)))
      hes
    }
  }

  validmu <- function(mu) {
    (sum(!is.finite(mu)) == 0) && all(0 < mu)
  }

  dev.resids <- function(y, mu, wt, disp = NULL) {
    NULL
  }

  aic <- function(y, mu, wt, dev) {
    -2 * sum((y * log(mu) - mu - log(1 - exp(-mu) - mu * exp(-mu)) -
                log(factorial(y))) * wt)
  }

  pointEst <- function (disp = NULL, pw, lambda, contr = FALSE) {
    N <- (pw * (1 - lambda * exp(-lambda)) /
         (1 - exp(-lambda) - lambda * exp(-lambda)))
    if(!contr) {
      N <- sum(N)
    }
    N
  }

  popVar <- function (beta, pw, lambda, disp = NULL, hess, X) {
    X <- as.data.frame(X)
    I <- -hess(beta)
    prob <- (1 - exp(-lambda) - lambda * exp(-lambda))
    term <- (1 - lambda * exp(-lambda)) ** 2
    
    f1 <- t(X) %*% (as.numeric(pw * lambda * (1 - exp(lambda)) /
                                 ((1 + lambda - exp(lambda)) ** 2)))
    
    f1 <- t(f1) %*% solve(as.matrix(I)) %*% f1
    
    f2 <- sum(pw * term * (1 - prob) / (prob ** 2))
    
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
            family = "zotpoisson")
  class(R) <- "family"
  R
}
