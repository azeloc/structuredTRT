analisar_processo <- function(sentencas, id, provider, model) {
  folder <- glue::glue("data-raw/runs/{provider}_{model}")
  fs::dir_create(folder)
  arq <- glue::glue("{folder}/{id}.json")
  if (!file.exists(arq)) {
    prompt <- system.file("prompts/prompt.md", package = "structuredTRT") |>
      readr::read_file()
    txt <- sentencas |>
      dplyr::filter(documento_id == id) |>
      dplyr::pull(txt)
    if (provider == "groq") {
      chat <- ellmer::chat_groq(model = model)
    } else if (provider == "google") {
      chat <- ellmer::chat_google_gemini(model = model)
    } else if (provider == "anthropic") {
      chat <- ellmer::chat_anthropic(model = model)
    } else if (provider == "grok") {
      chat <- ellmer::chat_openrouter(model = model)
    } else if (provider == "openai") {
      chat <- ellmer::chat_openai(model = model)
    } else {
      stop("Provider não suportado")
    }
    chat$set_system_prompt(prompt)
    chat$chat(txt, echo = FALSE)
    chat$last_turn()@json |>
      jsonlite::write_json(arq, auto_unbox = TRUE, pretty = TRUE)
  }
}
