metadados <- fs::dir_ls(
  "data-raw/cpopg",
  recurse = TRUE,
  type = "file",
  glob = "*.json"
) |>
  purrr::map(purrr::possibly(\(x) {
    jsonlite::read_json(x, simplifyDataFrame = TRUE)
  })) |>
  purrr::compact()

tramitacao_atual <- metadados |>
  purrr::map("tramitacaoAtual") |>
  tibble::enframe() |>
  dplyr::mutate(
    grau = purrr::map(value, \(x) purrr::pluck(x, "grau", "sigla")),
    grau = as.character(grau)
  )

tramitacao_atual_g1 <- tramitacao_atual |>
  dplyr::filter(grau == "G1")

tramitacoes_list <- metadados |>
  purrr::map("tramitacoes") |>
  purrr::compact() |>
  tibble::enframe() |>
  dplyr::anti_join(tramitacao_atual_g1, by = "name") |>
  dplyr::mutate(
    value = purrr::map(value, \(x) dplyr::filter(x[[1]], grau$sigla == "G1"))
  ) |>
  dplyr::mutate(
    grau = purrr::map(value, \(x) purrr::pluck(x, "grau", "sigla")),
    grau = as.character(grau)
  )

tramitacoes_full <- dplyr::bind_rows(
  tramitacao_atual_g1,
  tramitacoes_list
) |>
  dplyr::rename(arquivo = name, grau_buscado = grau) |>
  tidyr::unnest(value)

tramitacoes_full |>
  dplyr::count(grau_buscado)

documentos <- tramitacoes_full |>
  dplyr::select(arquivo_json = arquivo, documentos) |>
  dplyr::filter(purrr::map_lgl(documentos, \(x) length(x) > 0)) |>
  tidyr::unnest(documentos)

tramitacoes_full |>
  dplyr::select(arquivo, assunto) |>
  tidyr::unnest() |>
  dplyr::count(descricao, sort = TRUE) |>
  print(n = 30)

# -----------------------------

arquivos_txt <- fs::dir_ls(
  "data-raw/cpopg",
  recurse = TRUE,
  type = "file",
  regexp = "(txt|html|TXT|HTML)$"
) |>
  tibble::enframe(name = "arquivo_txt", value = "path_txt") |>
  dplyr::mutate(
    txt = purrr::map_chr(path_txt, \(x) readr::read_file(x))
  )

library(reticulate)
reticulate::py_require("tiktoken")
tiktoken <- reticulate::import("tiktoken")
enc <- tiktoken$encoding_for_model("gpt-4.1")

sentencas <- arquivos_txt |>
  dplyr::mutate(arquivo = basename(path_txt)) |>
  tidyr::separate(
    arquivo,
    into = c("documento_id", "extensao"),
    sep = "_",
    extra = "merge",
    convert = TRUE
  ) |>
  dplyr::mutate(
    processo = basename(dirname(dirname(arquivo_txt))),
    tipo = toupper(extensao),
    tipo = abjutils::rm_accent(tipo)
  ) |>
  dplyr::filter(
    tipo %in% c("SENTENCA.TXT", "SENTENCA.HTML", "SENTENCA (COPIA).TXT"),
    !stringr::str_detect(txt, "Too Many Requests|^%PDF-1")
  ) |>
  dplyr::distinct(txt, .keep_all = TRUE) |>
  dplyr::mutate(tokens = purrr::map_int(txt, \(x) length(enc$encode(x)))) |>
  dplyr::filter(tokens < 40000)

usethis::use_data(sentencas, compress = "xz", overwrite = TRUE)
