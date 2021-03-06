#' Pipe operator
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
NULL

maybe_as_data_frame <- function(out, x) {
  if (is.data.frame(x)) {
    check_tibble()
    tibble::as_tibble(out)
  } else {
    out
  }
}

check_tibble <- function() {
  if (!is_installed("tibble")) {
    abort("The tibble package must be installed")
  }
}

recycle_args <- function(args) {
  lengths <- map_int(args, length)
  n <- max(lengths)

  stopifnot(all(lengths == 1L | lengths == n))
  to_recycle <- lengths == 1L
  args[to_recycle] <- lapply(args[to_recycle], function(x) rep.int(x, n))
  args
}

names2 <- function(x) {
  names(x) %||% rep("", length(x))
}

#' Infix attribute accessor
#'
#' @description
#'
#' \Sexpr[results=rd, stage=render]{purrr:::lifecycle("soft-deprecated")}
#'
#' Please use the `%@%` operator exported in rlang. It has an
#' interface more consistent with `@`: uses NSE, supports S4 fields,
#' and has an assignment variant.
#'
#' @param x Object
#' @param name Attribute name
#' @export
#' @name get-attr
#' @keywords internal
#' @examples
#' factor(1:3) %@% "levels"
#' mtcars %@% "class"
`%@%` <- function(x, name) {
  signal_soft_deprecated(paste_line(
    "`%@%` is soft-deprecated as of purrr 0.3.0.",
    "Please use the operator provided in rlang instead."
  ))
  attr(x, name, exact = TRUE)
}


#' Generate random sample from a Bernoulli distribution
#'
#' @param n Number of samples
#' @param p Probability of getting `TRUE`
#' @return A logical vector
#' @export
#' @examples
#' rbernoulli(10)
#' rbernoulli(100, 0.1)
rbernoulli <- function(n, p = 0.5) {
  stats::runif(n) > (1 - p)
}

#' Generate random sample from a discrete uniform distribution
#'
#' @param n Number of samples to draw.
#' @param a,b Range of the distribution (inclusive).
#' @export
#' @examples
#' table(rdunif(1e3, 10))
#' table(rdunif(1e3, 10, -5))
rdunif <- function(n, b, a = 1) {
  stopifnot(is.numeric(a), length(a) == 1)
  stopifnot(is.numeric(b), length(b) == 1)

  a1 <- min(a, b)
  b1 <- max(a, b)

  sample(b1 - a1 + 1, n, replace = TRUE) + a1 - 1
}

# magrittr placeholder
globalVariables(".")


has_names <- function(x) {
  nms <- names(x)
  if (is.null(nms)) {
    rep_along(x, FALSE)
  } else {
    !(is.na(nms) | nms == "")
  }
}

ndots <- function(...) nargs()

is_names <- function(nms) {
  is_character(nms) && !any(is.na(nms) | nms == "")
}

paste_line <- function(...) {
  paste(chr(...), collapse = "\n")
}

# From rlang
friendly_type_of <- function(x, length = FALSE) {
  if (is.object(x)) {
    return(sprintf("a `%s` object", paste_classes(x)))
  }

  friendly <- as_friendly_type(typeof(x))

  if (length && is_vector(x)) {
    friendly <- paste0(friendly, sprintf(" of length %s", length(x)))
  }

  friendly
}
as_friendly_type <- function(type) {
  switch(type,
    logical = "a logical vector",
    integer = "an integer vector",
    numeric = ,
    double = "a double vector",
    complex = "a complex vector",
    character = "a character vector",
    raw = "a raw vector",
    string = "a string",
    list = "a list",

    NULL = "NULL",
    environment = "an environment",
    externalptr = "a pointer",
    weakref = "a weak reference",
    S4 = "an S4 object",

    name = ,
    symbol = "a symbol",
    language = "a call",
    pairlist = "a pairlist node",
    expression = "an expression vector",
    quosure = "a quosure",
    formula = "a formula",

    char = "an internal string",
    promise = "an internal promise",
    ... = "an internal dots object",
    any = "an internal `any` object",
    bytecode = "an internal bytecode object",

    primitive = ,
    builtin = ,
    special = "a primitive function",
    closure = "a function",

    type
  )
}
paste_classes <- function(x) {
  paste(class(x), collapse = "/")
}

is_bool <- function(x) {
  is_logical(x, n = 1) && !is.na(x)
}

friendly_type_of_element <- function(x) {
  if (is.object(x)) {
    classes <- paste0("`", paste_classes(x), "`")
    if (single) {
      friendly <- sprintf("a single %s element", classes)
    } else {
      friendly <- sprintf("a %s element", classes)
    }
    return(friendly)
  }

  switch(typeof(x),
    logical   = "a single logical",
    integer   = "a single integer",
    double    = "a single double",
    complex   = "a single complex number",
    character = "a single string",
    raw       = "a single raw value",
    list      = "a list of one element",
    abort("Expected a base vector type")
  )
}

#' Box a final value for early termination
#'
#' @description
#'
#' A value boxed with `done()` signals to its caller that it
#' should stop iterating. Use it to shortcircuit a loop.
#'
#' Currently, [reduce()], [reduce2()], [accumulate()], and
#' [accumulate2()] support done boxes.
#'
#' @param x For `done()`, a value to box. For `is_done_box()`, a
#'   value to test.
#' @return A [boxed][rlang::new_box] value.
#'
#' @examples
#' done(3)
#'
#' x <- done(3)
#' is_done_box(x)
#' @export
done <- function(x) {
  if (missing(x)) {
    class <- c("rlang_box_done_empty", "rlang_box_done")
  } else {
    class <- "rlang_box_done"
  }
  new_box(maybe_missing(x), class)
}
#' @rdname done
#' @param empty Whether the box is empty. If `NULL`, `is_done_box()`
#'   returns `TRUE` for all done boxes. If `TRUE`, it returns `TRUE`
#'   only for empty boxes. Otherwise it returns `TRUE` only for
#'   non-empty boxes.
#' @export
is_done_box <- function(x, empty = NULL) {
  if (!inherits(x, "rlang_box_done")) {
    return(FALSE)
  }

  if (is_null(empty)) {
    return(TRUE)
  }

  inherits(x, "rlang_box_done_empty") == empty
}
#' @export
print.rlang_box_done <- function(x, ...) {
  cat("<done>\n")
  print(unbox(x))
}
