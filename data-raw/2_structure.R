devtools::load_all()

# estruturação dos dados com Gemini-2.5-flash
da_arqs <- fs::dir_ls(
  "data-raw/runs/",
  recurse = TRUE,
  type = "file",
  regexp = "json$"
) |>
  tibble::enframe(name = "path", value = "arquivo") |>
  dplyr::mutate(
    provider = stringr::str_extract(path, "(?<=data-raw/runs/)[^_]+"),
    json = purrr::map(arquivo, \(x) {
      jsonlite::read_json(x, simplifyDataFrame = TRUE)
    }),
    parsed = purrr::map2(provider, json, \(x, y) parse_document(x, y)),
    conteudo = purrr::map_chr(parsed, "output")
  )

safe_estruturar_dados <- purrr::possibly(
  estruturar_dados,
  otherwise = tibble::tibble(erro = "erro_estruturacao")
)
mirai::daemons(6)
da_arqs_estruturado <- da_arqs |>
  dplyr::mutate(
    estrutura = purrr::map(
      conteudo,
      purrr::in_parallel(
        \(x) {
          purrr::possibly(
            estruturar,
            otherwise = tibble::tibble(erro = "erro_estruturacao")
          )(x)
        },
        estruturar = estruturar_dados
      ),
      .progress = TRUE
    )
  )

da_arqs_estruturado_unnest <- da_arqs_estruturado |>
  tidyr::unnest(estrutura)

readr::write_rds(
  da_arqs_estruturado_unnest,
  "data-raw/da_arqs_estruturado.rds"
)

# library(reticulate)
# reticulate::py_require(c("tiktoken"))
# tiktoken <- reticulate::import("tiktoken")
# enc <- tiktoken$encoding_for_model("gpt-4.1")
# input_tokens <- length(enc$encode(prompt_structured))
# total_tokens <- purrr::map_dbl(
#   da_arqs$conteudo,
#   \(x) {
#     length(enc$encode(x)) + input_tokens
#   },
#   .progress = TRUE
# )
# sum(total_tokens)

# leitura dos dados diretamente do JSON -------

# análise dos arquivos JSON válidos ----------------------------------

dados <- fs::dir_ls(
  "data-raw/runs",
  recurse = TRUE,
  type = "file",
  glob = "*.json"
) |>
  tibble::enframe(name = "path", value = "arquivo") |>
  dplyr::mutate(
    conteudo = purrr::map(arquivo, \(x) {
      jsonlite::read_json(x, simplifyDataFrame = TRUE)
    }),
    provider = stringr::str_extract(path, "(?<=data-raw/runs/)[^_]+"),
    result = purrr::map2(provider, conteudo, parse_document)
  ) |>
  tidyr::unnest(result)

dados |>
  dplyr::mutate(
    output_json = stringr::str_extract(output, "(?<=```json)\\X*(?=```)"),
    output_json = stringr::str_squish(output_json),
    output_json = dplyr::if_else(
      is.na(output_json),
      output,
      output_json
    ),
    output_json = stringr::str_squish(output_json)
  ) |>
  dplyr::filter(stringr::str_detect(path, "nano")) |>
  dplyr::select(path, output, output_json)

dados_parsed <- dados |>
  dplyr::mutate(
    output_json = stringr::str_replace_all(output, "```json", "```"),
    output_json = stringr::str_extract(output_json, "(?<=```)\\X*(?=```)"),
    output_json = stringr::str_squish(output_json),
    output_json = dplyr::if_else(
      is.na(output_json),
      output,
      output_json
    ),
    output_json = stringr::str_remove_all(output_json, "^\\X*</think>"),
    output_json = stringr::str_remove_all(output_json, "```"),
    output_json = stringr::str_squish(output_json),
    output_json_obj = purrr::map(
      output_json,
      purrr::possibly(
        \(x) jsonlite::fromJSON(x, simplifyDataFrame = TRUE),
        list()
      )
    ),
    output_json_valid = purrr::map_lgl(output_json_obj, \(x) {
      !identical(x, list())
    }),
    model = basename(dirname(path))
  ) |>
  dplyr::select(
    path,
    provider,
    model,
    input_tokens,
    output_tokens,
    total_tokens,
    output,
    output_json,
    output_json_obj,
    output_json_valid
  )

dados_parsed |>
  dplyr::count(output_json_valid)


readr::write_rds(dados_parsed, "data-raw/da_parsed.rds")
