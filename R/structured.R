#' Define o tipo estruturado para extração de dados de sentenças trabalhistas
#'
#' @return Tipo estruturado para extração, do pacote ellmer
#' @export
structured_trt <- function() {
  structured_type <- ellmer::type_object(
    escopo = ellmer::type_boolean(
      description = "Faz parte do escopo? O documento deve ser uma sentença de mérito dos pedidos principais de um processo trabalhista."
    ),
    fora_escopo_motivo = ellmer::type_string(
      description = "Motivo de estar fora do escopo"
    ),
    dados_decisao = ellmer::type_object(
      gratuidade_pedida = ellmer::type_boolean(
        description = "Houve pedido de gratuidade?"
      ),
      gratuidade_concedida = ellmer::type_boolean(
        description = "A gratuidade foi concedida?",
        required = FALSE
      ),
      pedidos = ellmer::type_array(
        ellmer::type_object(
          categoria = ellmer::type_enum(
            description = "Categoria do pedido",
            values = c(
              "horas_extras",
              "adicional_periculosidade",
              "adicional_insalubridade",
              "ferias",
              "verbas_rescisorias",
              "reconhecimento_vinculo",
              "13_salario",
              "aviso_previo",
              "multas_fgts",
              "danos_morais",
              "recolhimento_fgts",
              "justa_causa",
              "honorarios_advogado",
              "outro"
            )
          ),
          breve_descricao = ellmer::type_string(
            description = "Breve descrição do pedido, em uma frase"
          ),
          decisao_pedido = ellmer::type_enum(
            description = "Decisão sobre o pedido, se foi procedente ou improcedente",
            values = c("procedente", "improcedente")
          )
        ),
        description = "Lista de pedidos (exceto gratuidade), com pelo menos um pedido, a menos que esteja fora do escopo"
      ),
      julgamento_final = ellmer::type_enum(
        description = "Julgamento final: procedente, parcialmente procedente, improcedente",
        values = c("procedente", "parcialmente_procedente", "improcedente")
      ),
      valor_condenacao = ellmer::type_number(
        description = "Valor total da condenação em reais ou null"
      ),
      percentual_sucumbencia = ellmer::type_number(
        description = "Percentual de sucumbência (0 a 100) ou null"
      ),
      custas = ellmer::type_number(
        description = "Valor das custas processuais em reais ou null"
      ),
      observacao = ellmer::type_string(
        description = "Caso alguma informação extraída ficou imprecisa por conta das regras de estruturação, explique brevemente"
      )
    )
  )
  structured_type
}

#' Faz o parse do resultado da extração estruturada
#'
#' @param list_result Lista com o resultado da extração estruturada
#'
#' @return Tibble com os dados estruturados
#'
#' @export
parse_result <- function(list_result) {
  escopo <- list_result |>
    purrr::compact() |>
    purrr::discard(is.list) |>
    tibble::as_tibble()

  pedidos <- list_result |>
    purrr::pluck("dados_decisao", "pedidos") |>
    tibble::as_tibble()

  dados_decisao <- list_result |>
    purrr::pluck("dados_decisao") |>
    purrr::compact() |>
    purrr::discard(is.list) |>
    tibble::as_tibble() |>
    dplyr::mutate(pedidos = list(pedidos))

  dplyr::bind_cols(escopo, dados_decisao)
}

#' Estrutura os dados que saem da extração
#'
#' @param txt Texto extraído do documento
#'
#' @return Tibble com os dados estruturados
#'
#' @export
estruturar_dados <- function(txt) {
  prompt_structured <- system.file(
    "prompts/prompt_structured.md",
    package = "structuredTRT"
  ) |>
    readr::read_file()
  chat_gemini <- ellmer::chat_google_gemini(
    model = "gemini-2.5-flash",
    params = ellmer::params(
      temperature = 0,
      thinking_config = list(thinking_budget = 0)
    )
  )
  chat_gemini$set_system_prompt(prompt_structured)
  result <- chat_gemini$chat_structured(txt, type = structured_trt())
  result_parsed <- parse_result(result)
  result_parsed
}
