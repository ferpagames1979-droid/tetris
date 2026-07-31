## 📌 game_view_controller.gd
## Controller da tela de jogo — spawn, gravidade, rotação manual e soft drop (Ep3)
## cell_size é derivado da textura em runtime (16/24/32/64px, o asset comanda)
class_name GameViewController
extends Control

const CLASS_NAME_LOG: String = "GameViewController"

const BLOCK_TEXTURE: Texture2D = preload("res://assets/textures/block_base.png")

const GRAVITY_INTERVAL: float = 0.8      ## segundos entre cada queda de 1 linha (velocidade normal)
const SOFT_DROP_INTERVAL: float = 0.05   ## segundos entre cada queda durante soft drop (acelerado)

var cell_size: int = 32  ## valor default, sobrescrito em _ready() pelo tamanho real da textura

var board_model: BoardModel
var current_piece: PieceModel
var active_block_visuals: Array[TextureRect] = []   ## só a peça ativa (redesenha a cada tick)
var locked_block_visuals: Dictionary = {}           ## blocos fixados na pilha (permanentes)
var is_soft_dropping: bool = false                  ## estado atual do soft drop

@onready var gravity_timer: Timer = $GravityTimer
@onready var block_container: Node2D = %BlockContainer
@onready var board_panel: Panel = %BoardPanel

## 📌 Inicializa cell_size a partir da textura, o board, timer e a primeira peça
func _ready() -> void:
	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"GameView iniciando...")

	_setup_cell_size_from_texture()
	_setup_board_panel_size()

	board_model = BoardModel.new()
	board_model.setup_empty_grid()

	board_panel.resized.connect(_center_board_container)

	gravity_timer.wait_time = GRAVITY_INTERVAL
	gravity_timer.timeout.connect(_on_gravity_tick)
	gravity_timer.start()

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"Timer de gravidade configurado: %.2fs" % GRAVITY_INTERVAL)

	call_deferred("_center_board_container")
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

## 📌 Define o tamanho mínimo do BoardPanel baseado no grid completo (cols x rows x cell_size)
func _setup_board_panel_size() -> void:
	var board_width: float = BoardModel.GRID_COLUMNS * cell_size
	var board_height: float = BoardModel.GRID_ROWS * cell_size

	board_panel.custom_minimum_size = Vector2(board_width, board_height)

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"BoardPanel dimensionado: %.0fx%.0f (cols=%d rows=%d cell_size=%d)" %
		[board_width, board_height, BoardModel.GRID_COLUMNS, BoardModel.GRID_ROWS, cell_size])

## 📌 Centraliza o BlockContainer dentro do BoardPanel com base no tamanho real do grid
func _center_board_container() -> void:
	var grid_width: float = BoardModel.GRID_COLUMNS * cell_size
	var grid_height: float = BoardModel.GRID_ROWS * cell_size

	var offset_x: float = (board_panel.size.x - grid_width) / 2.0
	var offset_y: float = (board_panel.size.y - grid_height) / 2.0

	block_container.position = Vector2(offset_x, offset_y)

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.DEBUG,
		"BlockContainer centralizado: offset=%s | board_panel.size=%s" % [str(block_container.position), str(board_panel.size)])

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

	SignalBus.GameViewControllerSignal_piece_spawned.emit(piece.type)
	_redraw_active_piece()

## 📌 A cada tick de gravidade, tenta descer 1 linha; se não puder, fixa a peça
func _on_gravity_tick() -> void:
	var next_cells: Array[Vector2i] = _cells_moved(Vector2i(1, 0))
	if board_model.can_place(next_cells):
		current_piece.grid_position.x += 1
		_redraw_active_piece()
	else:
		_lock_piece_and_spawn_next()

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
		return

	SignalBus.GameViewControllerSignal_piece_rotated.emit(current_piece.rotation_state)
	_redraw_active_piece()

## 📌 Move a peça 1 coluna pra esquerda, se possível
func move_left() -> void:
	var next_cells: Array[Vector2i] = _cells_moved(Vector2i(0, -1))
	if board_model.can_place(next_cells):
		current_piece.grid_position.y -= 1
		SignalBus.GameViewControllerSignal_piece_moved.emit(Vector2i(0, -1))
		_redraw_active_piece()
	else:
		PrintLogManager.printlog(CLASS_NAME_LOG,
			PrintLogManager.LogType.DEBUG,
			"move_left bloqueado: colisão")

## 📌 Move a peça 1 coluna pra direita, se possível
func move_right() -> void:
	var next_cells: Array[Vector2i] = _cells_moved(Vector2i(0, 1))
	if board_model.can_place(next_cells):
		current_piece.grid_position.y += 1
		SignalBus.GameViewControllerSignal_piece_moved.emit(Vector2i(0, 1))
		_redraw_active_piece()
	else:
		PrintLogManager.printlog(CLASS_NAME_LOG,
			PrintLogManager.LogType.DEBUG,
			"move_right bloqueado: colisão")

## 📌 Ativa o soft drop: acelera a gravidade enquanto a tecla estiver pressionada
func _start_soft_drop() -> void:
	if is_soft_dropping:
		return

	is_soft_dropping = true
	gravity_timer.wait_time = SOFT_DROP_INTERVAL
	gravity_timer.start()

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.DEBUG,
		"Soft drop ativado: intervalo=%.2fs" % SOFT_DROP_INTERVAL)

## 📌 Desativa o soft drop: volta a gravidade pro intervalo normal
func _stop_soft_drop() -> void:
	if not is_soft_dropping:
		return

	is_soft_dropping = false
	gravity_timer.wait_time = GRAVITY_INTERVAL
	gravity_timer.start()

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.DEBUG,
		"Soft drop desativado: intervalo=%.2fs" % GRAVITY_INTERVAL)

## 📌 Captura input de teclado: rotação (cima/W), movimento (esquerda/direita) e soft drop (baixo/S)
func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:
				rotate_piece()
			KEY_LEFT, KEY_A:
				move_left()
			KEY_RIGHT, KEY_D:
				move_right()
			KEY_DOWN, KEY_S:
				_start_soft_drop()
	else:
		match event.keycode:
			KEY_DOWN, KEY_S:
				_stop_soft_drop()

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

	var locked_cells: Array[Vector2i] = current_piece.get_occupied_cells()

	for cell in locked_cells:
		board_model.grid[cell.x][cell.y] = current_piece.type + 1
		var block: TextureRect = _create_block_visual(cell, current_piece.type)
		block_container.add_child(block)
		locked_block_visuals[cell] = block

	SignalBus.GameViewControllerSignal_piece_locked.emit(current_piece.type, locked_cells)

	for block in active_block_visuals:
		block.queue_free()
	active_block_visuals.clear()

	_spawn_new_piece()

## 📌 Recria SÓ os blocos visuais da peça ativa (a cada queda/rotação/movimento)
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

## 📌 Trata o game over: para o timer, emite sinal e loga o evento (ainda sem tela de game over)
func _handle_game_over() -> void:
	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.ERROR,
		"GAME OVER — parando timer. Total de linhas: %d | Level: %d" %
		[board_model.total_lines_cleared, board_model.current_level])

	SignalBus.GameViewControllerSignal_game_over.emit(board_model.total_lines_cleared, board_model.current_level)
	gravity_timer.stop()
