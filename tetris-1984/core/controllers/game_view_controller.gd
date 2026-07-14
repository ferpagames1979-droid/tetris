## 📌 game_view_controller.gd
## Controller da tela de jogo — spawn, gravidade e demo de rotação (Ep1)
## cell_size é derivado da textura em runtime (16/24/32/64px, o asset comanda)
class_name GameViewController
extends Node2D

const CLASS_NAME_LOG: String = "GameViewController"

const BLOCK_TEXTURE: Texture2D = preload("res://assets/textures/block_base.png")

const GRAVITY_INTERVAL: float = 0.8    ## segundos entre cada queda de 1 linha
const DEMO_ACTION_INTERVAL: float = 1.2 ## segundos entre cada rotação automática

var cell_size: int = 32  ## valor default, sobrescrito em _ready() pelo tamanho real da textura

var board_model: BoardModel
var current_piece: PieceModel
var active_block_visuals: Array[TextureRect] = []   ## só a peça ativa (redesenha a cada tick)
var locked_block_visuals: Dictionary = {}           ## blocos fixados na pilha (permanentes)

@onready var gravity_timer: Timer = $GravityTimer
@onready var demo_timer: Timer = $DemoTimer
@onready var block_container: Node2D = $BlockContainer

## 📌 Inicializa cell_size a partir da textura, o board, timers e a primeira peça
func _ready() -> void:
	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"GameView iniciando...")

	_setup_cell_size_from_texture()

	board_model = BoardModel.new()
	board_model.setup_empty_grid()

	gravity_timer.wait_time = GRAVITY_INTERVAL
	gravity_timer.timeout.connect(_on_gravity_tick)
	gravity_timer.start()

	demo_timer.wait_time = DEMO_ACTION_INTERVAL
	demo_timer.timeout.connect(_on_demo_tick)
	demo_timer.start()

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"Timers configurados: gravidade=%.2fs | demo=%.2fs" % [GRAVITY_INTERVAL, DEMO_ACTION_INTERVAL])

	_spawn_new_piece()

## 📌 Lê o tamanho real da textura e define cell_size — a textura comanda o grid
func _setup_cell_size_from_texture() -> void:
	if BLOCK_TEXTURE == null:
		PrintLogManager.printlog(CLASS_NAME_LOG,
			PrintLogManager.LogType.WARNING,
			"BLOCK_TEXTURE não encontrada — usando cell_size default de %dpx" % cell_size)
		return

	var texture_width: int = int(BLOCK_TEXTURE.get_width())
	var texture_height: int = int(BLOCK_TEXTURE.get_height())

	if texture_width != texture_height:
		PrintLogManager.printlog(CLASS_NAME_LOG,
			PrintLogManager.LogType.WARNING,
			"Textura não é quadrada (%dx%d) — usando largura como cell_size" % [texture_width, texture_height])

	cell_size = texture_width

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"cell_size definido pela textura: %dpx" % cell_size)

## 📌 Cria uma nova peça sempre no centro do grid, no topo
func _spawn_new_piece() -> void:
	var piece: PieceModel = PieceModel.new()
	piece.type = randi() % PieceModel.PieceType.size()
	piece.rotation_state = 0
	piece.grid_position = Vector2i(0, (BoardModel.GRID_COLUMNS / 2) - 2)
	current_piece = piece

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"Nova peça spawnada: tipo=%s posição=%s" % [PieceModel.PieceType.keys()[piece.type], str(piece.grid_position)])

	if not board_model.can_place(current_piece.get_occupied_cells()):
		PrintLogManager.printlog(CLASS_NAME_LOG,
			PrintLogManager.LogType.ERROR,
			"GAME OVER: nova peça não coube na posição de spawn (Block Out)")
		_handle_game_over()
		return

	_redraw_active_piece()

## 📌 A cada tick de gravidade, tenta descer 1 linha; se não puder, fixa a peça
func _on_gravity_tick() -> void:
	var next_cells: Array[Vector2i] = _cells_moved(Vector2i(1, 0))
	if board_model.can_place(next_cells):
		current_piece.grid_position.x += 1
		_redraw_active_piece()
	else:
		_lock_piece_and_spawn_next()

## 📌 Demo automática: rotaciona a peça enquanto ela cai (Ep1, sem teclado)
func _on_demo_tick() -> void:
	rotate_piece()

## 📌 Rotaciona a peça pro próximo estado SRS, se possível (valida e desfaz se necessário)
func rotate_piece() -> void:
	var original_state: int = current_piece.rotation_state
	current_piece.advance_rotation()

	if not board_model.can_place(current_piece.get_occupied_cells()):
		PrintLogManager.printlog(CLASS_NAME_LOG,
			PrintLogManager.LogType.DEBUG,
			"Rotação rejeitada (colisão) — revertendo")
		current_piece.revert_rotation(original_state)

	_redraw_active_piece()

## 📌 Retorna as células da peça caso ela se mova pelo offset informado
func _cells_moved(offset: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = current_piece.get_occupied_cells()
	var moved: Array[Vector2i] = []
	for cell in cells:
		moved.append(cell + offset)
	return moved

## 📌 Fixa a peça atual no grid (lógico + visual permanente) e spawna a próxima
func _lock_piece_and_spawn_next() -> void:
	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"Peça travada: tipo=%s posição=%s" % [PieceModel.PieceType.keys()[current_piece.type], str(current_piece.grid_position)])

	for cell in current_piece.get_occupied_cells():
		board_model.grid[cell.x][cell.y] = current_piece.type + 1
		var block: TextureRect = _create_block_visual(cell, current_piece.type)
		block_container.add_child(block)
		locked_block_visuals[cell] = block

	for block in active_block_visuals:
		block.queue_free()
	active_block_visuals.clear()

	_spawn_new_piece()

## 📌 Recria SÓ os blocos visuais da peça ativa (a cada queda/rotação)
func _redraw_active_piece() -> void:
	for block in active_block_visuals:
		block.queue_free()
	active_block_visuals.clear()

	for cell in current_piece.get_occupied_cells():
		var block: TextureRect = _create_block_visual(cell, current_piece.type)
		block_container.add_child(block)
		active_block_visuals.append(block)

## 📌 Cria um TextureRect de bloco escalado corretamente pro cell_size (única fonte de criação)
func _create_block_visual(cell: Vector2i, piece_type: int) -> TextureRect:
	var block: TextureRect = TextureRect.new()
	block.texture = BLOCK_TEXTURE
	block.self_modulate = PieceModel.PIECE_COLORS[piece_type]
	block.stretch_mode = TextureRect.STRETCH_SCALE
	block.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	block.custom_minimum_size = Vector2(cell_size, cell_size)
	block.size = Vector2(cell_size, cell_size)
	block.position = Vector2(cell.y * cell_size, cell.x * cell_size)
	return block

## 📌 Trata o game over: para os timers e loga o evento (Ep1: sem tela de game over ainda)
func _handle_game_over() -> void:
	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.ERROR,
		"GAME OVER — parando timers. Total de linhas: %d | Level: %d" %
		[board_model.total_lines_cleared, board_model.current_level])

	gravity_timer.stop()
	demo_timer.stop()
