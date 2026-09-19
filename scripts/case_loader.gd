class_name CaseLoader
extends RefCounted

const SCORE_KEYS: Array[String] = [
    "dependencia",
    "delegacao_cognitiva",
    "autonomia",
    "pensamento_critico",
    "uso_responsavel",
]

func load_cases(path: String) -> Array:
    if not FileAccess.file_exists(path):
        push_error("Arquivo de casos nao encontrado: %s" % path)
        return []

    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Nao foi possivel abrir o arquivo de casos: %s" % path)
        return []

    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Array or parsed.is_empty():
        push_error("O arquivo de casos precisa conter um array nao vazio.")
        return []

    var validated_cases: Array = []
    for index in range(parsed.size()):
        var validated_case := _validate_case(parsed[index], index)
        if validated_case.is_empty():
            return []
        validated_cases.append(validated_case)

    return validated_cases

func _validate_case(raw_case: Variant, index: int) -> Dictionary:
    if not raw_case is Dictionary:
        push_error("Caso %d invalido: esperado um objeto." % (index + 1))
        return {}

    var case_data: Dictionary = raw_case
    if not _has_non_empty_string(case_data, "text"):
        push_error("Caso %d invalido: campo 'text' ausente." % (index + 1))
        return {}
    if not case_data.has("options") or not case_data["options"] is Array or case_data["options"].is_empty():
        push_error("Caso %d invalido: 'options' precisa ser um array nao vazio." % (index + 1))
        return {}
    if not _has_non_empty_string(case_data, "moral"):
        push_error("Caso %d invalido: campo 'moral' ausente." % (index + 1))
        return {}

    for option_index in range(case_data["options"].size()):
        if not _validate_option(case_data["options"][option_index], index, option_index):
            return {}

    return case_data

func _validate_option(raw_option: Variant, case_index: int, option_index: int) -> bool:
    if not raw_option is Dictionary:
        push_error("Caso %d, opcao %d invalida: esperado um objeto." % [case_index + 1, option_index + 1])
        return false

    var option: Dictionary = raw_option
    if not _has_non_empty_string(option, "text"):
        push_error("Caso %d, opcao %d invalida: campo 'text' ausente." % [case_index + 1, option_index + 1])
        return false
    if not option.has("weights") or not option["weights"] is Dictionary:
        push_error("Caso %d, opcao %d invalida: campo 'weights' ausente." % [case_index + 1, option_index + 1])
        return false

    for score_key in option["weights"].keys():
        if score_key not in SCORE_KEYS or not (option["weights"][score_key] is int or option["weights"][score_key] is float):
            push_error("Peso invalido '%s' no caso %d, opcao %d." % [score_key, case_index + 1, option_index + 1])
            return false

    return true

func _has_non_empty_string(data: Dictionary, key: String) -> bool:
    return data.has(key) and data[key] is String and not data[key].strip_edges().is_empty()
