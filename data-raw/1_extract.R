devtools::load_all()

set.seed(1)
amostra <- sentencas |>
  dplyr::slice_sample(prop = 1)

models <- list(
  google = c("gemini-2.5-flash", "gemini-2.5-pro"),
  openai = c("gpt-4.1-nano", "gpt-4.1-mini", "gpt-4.1", "gpt-5.1"),
  groq = c(
    "llama-3.1-8b-instant",
    "llama-3.3-70b-versatile",
    "openai/gpt-oss-120b",
    "openai/gpt-oss-20b",
    "meta-llama/llama-4-maverick-17b-128e-instruct",
    "meta-llama/llama-4-scout-17b-16e-instruct",
    "moonshotai/kimi-k2-instruct-0905",
    "qwen/qwen3-32b"
  ),
  anthropic = c(
    "claude-sonnet-4-5-20250929",
    "claude-haiku-4-5-20251001"
  ),
  grok = c(
    "x-ai/grok-4.1-fast"
  )
)

da_models <- models |>
  tibble::enframe() |>
  tidyr::unnest(value) |>
  # ordem para usar primeiro os modelos mais rápidos
  dplyr::slice(c(3, 1, 18, 17, 4, 7:15, 5, 2, 6, 16)) |>
  tibble::rowid_to_column()

safe_analisar_processo <- purrr::possibly(analisar_processo, otherwise = NULL)

da_models |>
  dplyr::group_split(rowid) |>
  purrr::walk(
    \(x) {
      purrr::walk(amostra$documento_id, \(id) {
        safe_analisar_processo(sentencas, id, x$name, x$value)
      })
    },
    .progress = TRUE
  )
