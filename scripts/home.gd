extends Control

const CASE_LOADER_SCRIPT = preload("res://scripts/case_loader.gd")

@onready var question_index: Label = $MarginContainer/Panel/Content/QuestionIndex
@onready var question_text: RichTextLabel = $MarginContainer/Panel/Content/QuestionText
@onready var options_container: VBoxContainer = $MarginContainer/Panel/Content/OptionsContainer
@onready var feedback_label: Label = $MarginContainer/Panel/Content/Feedback
@onready var next_button: Button = $MarginContainer/Panel/Content/NextButton

enum GameState { DECISION, FEEDBACK, RESULT }

var questions: Array = []
var current_index: int = 0
var state: GameState = GameState.DECISION
var option_buttons: Array[Button] = []

var score: Dictionary = {
	"dependencia": 0,
	"delegacao_cognitiva": 0,
	"autonomia": 0,
	"pensamento_critico": 0,
	"uso_responsavel": 0,
}

func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	load_questions()
	if questions.is_empty():
		_show_load_error()
	else:
		show_question()

func load_questions() -> void:
	questions = CASE_LOADER_SCRIPT.new().load_cases("res://data/questions.json")

func show_question() -> void:
	if current_index >= questions.size():
		show_final_result()
		return

	state = GameState.DECISION
	var question = questions[current_index]
	question_index.text = "Pergunta %d de %d" % [current_index + 1, questions.size()]
	question_text.text = question.get("text", "Pergunta")
	feedback_label.text = ""
	next_button.visible = false
	_clear_option_buttons()

	var options = question.get("options", [])
	for index in range(options.size()):
		var button := Button.new()
		button.text = options[index].get("text", "Opção")
		button.custom_minimum_size = Vector2(0, 46)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		_style_option_button(button)
		button.pressed.connect(_on_option_pressed.bind(index))
		options_container.add_child(button)
		option_buttons.append(button)

func _on_option_pressed(index: int) -> void:
	if state != GameState.DECISION:
		return

	state = GameState.FEEDBACK
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
	if state == GameState.RESULT:
		restart_game()
		return

	if state != GameState.FEEDBACK:
		return

	if current_index < questions.size() - 1:
		current_index += 1
		show_question()
		return

	show_final_result()

func show_final_result() -> void:
	state = GameState.RESULT

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

	_clear_option_buttons()

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

func _clear_option_buttons() -> void:
	for button in option_buttons:
		button.queue_free()
	option_buttons.clear()

func _show_load_error() -> void:
	state = GameState.RESULT
	question_index.text = "Nao foi possivel carregar os casos"
	question_text.text = "Verifique o arquivo data/questions.json."
	feedback_label.text = "O jogo nao pode iniciar com dados invalidos."
	next_button.visible = false

func _style_option_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color(1, 0.94, 0.82, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 0.95, 1))
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.25, 0.18, 0.11, 0.9)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.38, 0.27, 0.16, 0.95)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.18, 0.12, 0.07, 0.95)))
	button.add_theme_stylebox_override("disabled", _make_button_style(Color(0.3, 0.25, 0.19, 0.65)))

func _make_button_style(background_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	return style
