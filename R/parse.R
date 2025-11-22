parse_anthropic <- function(x) {
  input_tokens <- x$usage$input_tokens
  output <- x$content$text
  output_tokens <- x$usage$output_tokens
  tibble::tibble(
    output = output,
    input_tokens = input_tokens,
    output_tokens = output_tokens,
    total_tokens = input_tokens + output_tokens
  )
}

parse_openai <- function(x) {
  input_tokens <- x$usage$prompt_tokens
  output <- x$choices$message$content
  output_tokens <- x$usage$completion_tokens
  tibble::tibble(
    output = output,
    input_tokens = input_tokens,
    output_tokens = output_tokens,
    total_tokens = input_tokens + output_tokens
  )
}

parse_google <- function(x) {
  input_tokens <- x$usage$promptTokenCount
  output <- x$candidates[[1]]$parts[[1]]$text
  output_tokens <- x$usage$candidatesTokenCount + x$usage$thoughtsTokenCount
  tibble::tibble(
    output = output,
    input_tokens = input_tokens,
    output_tokens = output_tokens,
    total_tokens = input_tokens + output_tokens
  )
}

parse_xai <- function(x) {
  input_tokens <- x$usage$prompt_tokens
  output <- x$choices$message$content
  output_tokens <- x$usage$completion_tokens
  tibble::tibble(
    output = output,
    input_tokens = input_tokens,
    output_tokens = output_tokens,
    total_tokens = input_tokens + output_tokens
  )
}

parse_groq <- function(x) {
  input_tokens <- x$usage$prompt_tokens
  output <- x$choices$message$content
  output_tokens <- x$usage$completion_tokens
  tibble::tibble(
    output = output,
    input_tokens = input_tokens,
    output_tokens = output_tokens,
    total_tokens = input_tokens + output_tokens
  )
}

parse_document <- function(provider, x) {
  if (provider == "anthropic") {
    parse_anthropic(x)
  } else if (provider == "openai") {
    parse_openai(x)
  } else if (provider == "google") {
    parse_google(x)
  } else if (provider == "grok") {
    parse_xai(x)
  } else if (provider == "groq") {
    parse_groq(x)
  } else {
    stop("Provider não suportado")
  }
}
