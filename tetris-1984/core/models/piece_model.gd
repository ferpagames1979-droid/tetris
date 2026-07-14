## 📌 piece_model.gd
## Model puro de um tetromino — sem lógica de cena
class_name PieceModel
extends Resource

const CLASS_NAME_LOG: String = "PieceModel"

enum PieceType { I, O, T, S, Z, J, L }

## ── FORMATOS SRS (4 estados de rotação, grade 4x4) ──
const SHAPES: Dictionary = {
	PieceType.I: [
		[Vector2i(1,0), Vector2i(1,1), Vector2i(1,2), Vector2i(1,3)],
		[Vector2i(0,2), Vector2i(1,2), Vector2i(2,2), Vector2i(3,2)],
		[Vector2i(2,0), Vector2i(2,1), Vector2i(2,2), Vector2i(2,3)],
		[Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1)],
	],
	PieceType.O: [
		[Vector2i(0,1), Vector2i(0,2), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(0,1), Vector2i(0,2), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(0,1), Vector2i(0,2), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(0,1), Vector2i(0,2), Vector2i(1,1), Vector2i(1,2)],
	],
	PieceType.T: [
		[Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(0,1), Vector2i(1,1), Vector2i(1,2), Vector2i(2,1)],
		[Vector2i(1,0), Vector2i(1,1), Vector2i(1,2), Vector2i(2,1)],
		[Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
	],
	PieceType.S: [
		[Vector2i(0,1), Vector2i(0,2), Vector2i(1,0), Vector2i(1,1)],
		[Vector2i(0,1), Vector2i(1,1), Vector2i(1,2), Vector2i(2,2)],
		[Vector2i(0,1), Vector2i(0,2), Vector2i(1,0), Vector2i(1,1)],
		[Vector2i(0,1), Vector2i(1,1), Vector2i(1,2), Vector2i(2,2)],
	],
	PieceType.Z: [
		[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(0,2), Vector2i(1,1), Vector2i(1,2), Vector2i(2,1)],
		[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(0,2), Vector2i(1,1), Vector2i(1,2), Vector2i(2,1)],
	],
	PieceType.J: [
		[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(0,1), Vector2i(0,2), Vector2i(1,1), Vector2i(2,1)],
		[Vector2i(1,0), Vector2i(1,1), Vector2i(1,2), Vector2i(2,2)],
		[Vector2i(0,1), Vector2i(1,1), Vector2i(2,0), Vector2i(2,1)],
	],
	PieceType.L: [
		[Vector2i(0,2), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)],
		[Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(2,2)],
		[Vector2i(1,0), Vector2i(1,1), Vector2i(1,2), Vector2i(2,0)],
		[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
	],
}

## ── CORES OFICIAIS (fiel ao Guideline) ──
const PIECE_COLORS: Dictionary = {
	PieceType.I: Color.CYAN,
	PieceType.O: Color.YELLOW,
	PieceType.T: Color.PURPLE,
	PieceType.S: Color.GREEN,
	PieceType.Z: Color.RED,
	PieceType.J: Color.BLUE,
	PieceType.L: Color.ORANGE,
}

## ── ESTADO ──
var type: PieceType
var rotation_state: int = 0
var grid_position: Vector2i

## 📌 Retorna as coordenadas absolutas dos 4 blocos da peça no grid atual
func get_occupied_cells() -> Array[Vector2i]:
	var shape: Array = SHAPES[type][rotation_state]
	var cells: Array[Vector2i] = []
	for cell in shape:
		cells.append(Vector2i(cell.x + grid_position.x, cell.y + grid_position.y))

	if cells.size() != 4:
		PrintLogManager.printlog(CLASS_NAME_LOG,
			PrintLogManager.LogType.WARNING,
			"get_occupied_cells retornou %d células (esperado: 4) — tipo=%s rotation=%d" %
			[cells.size(), PieceType.keys()[type], rotation_state])

	return cells

## 📌 Avança a rotação para o próximo estado SRS (0→1→2→3→0), sem validar colisão
## Validação de colisão é responsabilidade do Controller (usa BoardModel.can_place)
func advance_rotation() -> void:
	var previous_state: int = rotation_state
	rotation_state = (rotation_state + 1) % 4

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.DEBUG,
		"Rotação avançada: %d -> %d (tipo=%s)" % [previous_state, rotation_state, PieceType.keys()[type]])

## 📌 Reverte a rotação para o estado anterior informado (usado quando rotação é rejeitada)
func revert_rotation(previous_state: int) -> void:
	rotation_state = previous_state
	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.DEBUG,
		"Rotação revertida para estado %d (tipo=%s)" % [previous_state, PieceType.keys()[type]])
