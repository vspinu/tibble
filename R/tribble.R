#' Row-wise tibble creation
#'
#' Create \code{\link{tibble}}s laying out the data in rows, rather than
#' in columns. This is useful for small tables of data where readability is
#' important.  Please see \link{tibble-package} for a general introduction.
#'
#' \code{frame_data()} is an older name for \code{tribble()}. It will eventually
#' be phased out.
#'
#' @param ... Arguments specifying the structure of a \code{tibble}.
#'   Variable names should be formulas, and may only appear before the data.
#' @return A \code{\link{tibble}}.
#' @export
#' @examples
#' tribble(
#'   ~colA, ~colB,
#'   "a",   1,
#'   "b",   2,
#'   "c",   3
#' )
#'
#' # tribble will create a list column if the value in any cell is
#' # not a scalar
#' tribble(
#'   ~x,  ~y,
#'   "a", 1:3,
#'   "b", 4:6
#' )
tribble <- function(...) {

  dots <- list(...)

  # Extract the names.
  frame_names <- character()
  i <- 1
  while (TRUE) {
    if (i > length(dots)) {
      out <- rep(list(logical()), length(frame_names))
      names(out) <- frame_names
      return(as_tibble(out))
    }

    el <- dots[[i]]
    if (!is.call(el))
      break

    if (!identical(el[[1]], as.name("~")))
      break

    if (length(el) != 2) {
      stopc("expected a column name with a single argument; e.g. '~ name'")
    }

    candidate <- el[[2]]
    if (!(is.symbol(candidate) || is.character(candidate))) {
      stopc("expected a symbol or string denoting a column name")
    }

    frame_names <- c(frame_names, as.character(el[[2]]))

    i <- i + 1
  }

  if (!length(frame_names)) {
    stopc("no column names detected in 'tribble()' call")
  }

  frame_rest <- dots[i:length(dots)]
  n_elements <- length(frame_rest)

  # Figure out the associated number of rows and number of columns,
  # and validate that the supplied formula produces a rectangular
  # structure.
  frame_ncol <- length(frame_names)
  if (n_elements %% frame_ncol != 0) {
    stopc(
      sprintf(
        "invalid 'tribble()' specification: had %s elements and %s columns",
        n_elements,
        frame_ncol
      )
    )
  }

  frame_mat <- matrix(frame_rest, ncol = frame_ncol, byrow = TRUE)
  frame_col <- lapply(seq_len(ncol(frame_mat)), function(i) {
    col <- frame_mat[, i]
    if (any(vapply(col, needs_list_col, logical(1L)))) {
      col
    } else {
      unlist(col)
    }
  })

  # Create a tbl_df and return it
  names(frame_col) <- frame_names
  as_tibble(frame_col)
}

#' @export
#' @rdname tribble
frame_data <- tribble
