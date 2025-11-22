# avaliacao ------------------------------
arrumar_nome_modelo <- function(model) {
  model <- stringr::str_remove_all(
    model,
    "groq_|openai_|google_|anthropic_|claude-"
  )
  model <- stringr::str_remove(model, "-[0-9]{3,}$")
  model <- stringr::str_remove(model, "-17b-[0-9]{2,}e-instruct")
  model <- stringr::str_remove(model, "-versatile|-instant|-instruct")
  model
}

arrumar_nome_provider <- function(provider) {
  provider <- stringr::str_to_title(provider)
  provider <- dplyr::if_else(provider == "Grok", "xAI", provider)
  provider
}

da_structured <- readr::read_rds("data-raw/da_arqs_estruturado.rds") |>
  dplyr::mutate(model = basename(dirname(path))) |>
  dplyr::mutate(
    model = arrumar_nome_modelo(model),
    provider = arrumar_nome_provider(provider)
  )

dados_parsed <- readr::read_rds("data-raw/da_parsed.rds") |>
  dplyr::mutate(
    model = arrumar_nome_modelo(model),
    provider = arrumar_nome_provider(provider)
  )

custos <- tibble::tribble(
  ~model                                 , ~cost_1M_input , ~cost_1M_output ,
  "google_gemini-2.5-pro"                , 1.250          , 10.00           ,
  "google_gemini-2.5-flash"              , 0.300          ,  2.50           ,
  "openai_gpt-4.1"                       , 3.000          , 12.00           ,
  "openai_gpt-4.1-nano"                  , 0.200          ,  0.80           ,
  "openai_gpt-4.1-mini"                  , 0.800          ,  3.20           ,
  "openai_gpt-5.1"                       , 1.250          , 10.00           ,
  "anthropic_claude-haiku-4-5-20251001"  , 1.000          ,  5.00           ,
  "anthropic_claude-sonnet-4-5-20250929" , 3.000          , 15.00           ,
  "gpt-oss-120b"                         , 0.150          ,  0.60           ,
  "gpt-oss-20b"                          , 0.075          ,  0.30           ,
  "groq_llama-3.1-8b-instant"            , 0.050          ,  0.08           ,
  "groq_llama-3.3-70b-versatile"         , 0.590          ,  0.79           ,
  "llama-4-maverick-17b-128e-instruct"   , 0.200          ,  0.60           ,
  "llama-4-scout-17b-16e-instruct"       , 0.110          ,  0.34           ,
  "kimi-k2-instruct-0905"                , 1.000          ,  3.00           ,
  "qwen3-32b"                            , 0.290          ,  0.59           ,
  "grok-4.1-fast"                        , 0.200          ,  0.50
) |>
  dplyr::mutate(model = arrumar_nome_modelo(model))

da_cost <- dados_parsed |>
  dplyr::inner_join(custos, by = "model") |>
  dplyr::mutate(
    cost = (input_tokens / 1e6) *
      cost_1M_input +
      (output_tokens / 1e6) * cost_1M_output
  ) |>
  dplyr::group_by(model) |>
  dplyr::summarise(
    total_cost = sum(cost),
    avg_cost = mean(cost)
  ) |>
  dplyr::arrange(dplyr::desc(total_cost))

da_report <- da_structured |>
  dplyr::inner_join(
    dplyr::select(
      dados_parsed,
      path,
      output_json_valid,
      input_tokens,
      output_tokens
    ),
    "path"
  ) |>
  dplyr::inner_join(custos, by = "model") |>
  dplyr::mutate(
    cost = (input_tokens / 1e6) *
      cost_1M_input +
      (output_tokens / 1e6) * cost_1M_output
  ) |>
  dplyr::transmute(
    path,
    provider,
    model,
    cost,
    output_json_valid,
    escopo,
    fora_escopo_motivo,
    gratuidade_pedida,
    gratuidade_concedida,
    julgamento_final,
    valor_condenacao,
    percentual_sucumbencia,
    custas,
    observacao,
    pedidos
  )

usethis::use_data(da_report, overwrite = TRUE)
