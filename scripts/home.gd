extends Control

@onready var question_index: Label = $MarginContainer/Panel/Content/QuestionIndex
@onready var question_text: RichTextLabel = $MarginContainer/Panel/Content/QuestionText
@onready var feedback_label: Label = $MarginContainer/Panel/Content/Feedback
@onready var next_button: Button = $MarginContainer/Panel/Content/NextButton
@onready var option_buttons: Array[Button] = [
    $MarginContainer/Panel/Content/OptionsContainer/Option1,
    $MarginContainer/Panel/Content/OptionsContainer/Option2,
    $MarginContainer/Panel/Content/OptionsContainer/Option3,
    $MarginContainer/Panel/Content/OptionsContainer/Option4,
]

var questions: Array = []
var current_index: int = 0
var answered: bool = false
var is_final_result: bool = false

var score: Dictionary = {
    "dependencia": 0,
    "delegacao_cognitiva": 0,
    "autonomia": 0,
    "pensamento_critico": 0,
    "uso_responsavel": 0,
}

func _ready() -> void:
    _connect_options()
    load_questions()
    show_question()

func _connect_options() -> void:
    for i in range(option_buttons.size()):
        option_buttons[i].pressed.connect(_on_option_pressed.bind(i))
    next_button.pressed.connect(_on_next_button_pressed)

func load_questions() -> void:
    var file: FileAccess = FileAccess.open("res://data/questions.json", FileAccess.READ)
    if file == null:
        questions = [
            {
                "text": "Você precisa entregar um trabalho importante e a IA oferece um texto pronto em segundos. O que fazer?",
                "options": [
                    {"text": "Copiar inteiro sem revisar", "weights": {"dependencia": 4, "delegacao_cognitiva": 5, "autonomia": -2}},
                    {"text": "Usar a IA para estruturar e depois estudar o conteúdo", "weights": {"autonomia": 2, "uso_responsavel": 3, "pensamento_critico": 2}},
                    {"text": "Pedir para a IA fazer a redação e só entregar", "weights": {"dependencia": 5, "delegacao_cognitiva": 6, "autonomia": -3}},
                    {"text": "Consultar a IA como apoio e comparar com fontes confiáveis", "weights": {"uso_responsavel": 4, "pensamento_critico": 3, "autonomia": 2}}
                ],
                "moral": "Delegar todo o raciocínio pode reduzir a própria aprendizagem."
            },
            {
                "text": "Seu professor pede uma explicação de um conceito complexo. Você vê uma resposta da IA bem convincente, mas sem fonte. O que faz?",
                "options": [
                    {"text": "Entregar sem verificar", "weights": {"dependencia": 3, "pensamento_critico": -2, "uso_responsavel": -2}},
                    {"text": "Verificar a informação em fontes confiáveis", "weights": {"pensamento_critico": 4, "uso_responsavel": 4, "autonomia": 2}},
                    {"text": "Aceitar porque a IA parece inteligente", "weights": {"dependencia": 2, "delegacao_cognitiva": 3, "pensamento_critico": -3}},
                    {"text": "Pedir à IA para listar dúvidas e depois pesquisar", "weights": {"uso_responsavel": 3, "autonomia": 2, "pensamento_critico": 2}}
                ],
                "moral": "A IA pode gerar respostas plausíveis, mas a checagem continua sendo responsabilidade humana."
            },
            {
                "text": "Você precisa resolver um problema de lógica, mas a IA já oferece a solução pronta. Qual é a melhor decisão?",
                "options": [
                    {"text": "Entregar a solução pronta sem entender", "weights": {"dependencia": 4, "delegacao_cognitiva": 5, "autonomia": -3}},
                    {"text": "Usar a IA só para pistas e tentar resolver sozinho", "weights": {"autonomia": 4, "pensamento_critico": 4, "uso_responsavel": 3}},
                    {"text": "Pedir a IA para fazer tudo e aprender depois", "weights": {"dependencia": 5, "delegacao_cognitiva": 5, "autonomia": -3}},
                    {"text": "Comparar a resposta da IA com seu próprio raciocínio", "weights": {"pensamento_critico": 4, "uso_responsavel": 4, "autonomia": 3}}
                ],
                "moral": "A aprendizagem real acontece quando você exercita o pensamento, não quando só recebe a resposta."
            }
        ]
        return

    var data = JSON.parse_string(file.get_as_text())
    if typeof(data) == TYPE_ARRAY:
        questions = data

func show_question() -> void:
    if current_index >= questions.size():
        show_final_result()
        return

    is_final_result = false
    answered = false
    var question = questions[current_index]
    question_index.text = "Pergunta %d de %d" % [current_index + 1, questions.size()]
    question_text.text = question.get("text", "Pergunta")
    feedback_label.text = ""
    next_button.visible = false

    var options = question.get("options", [])
    for i in range(option_buttons.size()):
        if i < options.size():
            option_buttons[i].text = options[i].get("text", "Opção")
            option_buttons[i].visible = true
            option_buttons[i].disabled = false
        else:
            option_buttons[i].visible = false
            option_buttons[i].disabled = true

func _on_option_pressed(index: int) -> void:
    if answered:
        return

    answered = true
    var question = questions[current_index]
    var option = question.get("options", [])[index]

    for key in score.keys():
        score[key] += int(option.get("weights", {}).get(key, 0))

    feedback_label.text = "Você escolheu: %s\n\n%s" % [option.get("text", "Opção"), question.get("moral", "")]
    next_button.visible = true
    next_button.text = "Próxima pergunta" if current_index < questions.size() - 1 else "Ver resultado"

    for button in option_buttons:
        button.disabled = true

func _on_next_button_pressed() -> void:
    if is_final_result:
        restart_game()
        return

    if current_index < questions.size() - 1:
        current_index += 1
        show_question()
        return

    show_final_result()

func show_final_result() -> void:
    is_final_result = true
    answered = true

    question_index.text = "Resultado final"
    question_text.text = "Seu perfil mostra tendência a: %s" % _generate_profile_summary()
    feedback_label.text = (
        "Dependência de IA: %d\n" +
        "Delegação cognitiva: %d\n" +
        "Autonomia: %d\n" +
        "Pensamento crítico: %d\n" +
        "Uso responsável: %d\n\n" +
        "Aviso: este resultado é uma simulação comportamental e não substitui diagnóstico profissional."
    ) % [
        score["dependencia"],
        score["delegacao_cognitiva"],
        score["autonomia"],
        score["pensamento_critico"],
        score["uso_responsavel"],
    ]

    for button in option_buttons:
        button.visible = false

    next_button.visible = true
    next_button.text = "Jogar novamente"

func _generate_profile_summary() -> String:
    if score["dependencia"] >= 7 and score["autonomia"] <= 1:
        return "alto uso dependente da IA."
    if score["uso_responsavel"] >= 7 and score["pensamento_critico"] >= 5:
        return "uso responsável e crítico da IA."
    if score["delegacao_cognitiva"] >= 8:
        return "delegação excessiva do raciocínio para a máquina."
    return "equilíbrio entre uso e autonomia, com espaço para melhorar."

func restart_game() -> void:
    current_index = 0
    for key in score.keys():
        score[key] = 0
    show_question()
