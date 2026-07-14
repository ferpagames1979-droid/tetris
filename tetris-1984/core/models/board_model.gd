## 📌 board_model.gd
## Model puro do grid do Tetris — sem lógica de cena
class_name BoardModel
extends Resource

const CLASS_NAME_LOG: String = "BoardModel"

## ── DIMENSÕES DO GRID (parametrizável) ──
const GRID_ROWS: int = 10
const GRID_COLUMNS: int = 10

## ── PROGRESSÃO DE LEVEL (parametrizável, fiel ao Guideline original) ──
const LINES_TO_LEVEL_UP: int = 10

## ── PONTUAÇÃO POR TIPO DE CLEAR (fiel ao original) ──
const LINE_CLEAR_SCORE: Dictionary = {
	1: 100,
	2: 300,
	3: 500,
	4: 800,
}

## ── ESTADO ──
var grid: Array = []
var current_level: int = 1
var total_lines_cleared: int = 0

## 📌 Inicializa o grid vazio com as dimensões definidas nas constantes
func setup_empty_grid() -> void:
	grid.clear()
	for row in range(GRID_ROWS):
		var new_row: Array = []
		new_row.resize(GRID_COLUMNS)
		new_row.fill(0)
		grid.append(new_row)

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"Grid inicializado: %dx%d" % [GRID_ROWS, GRID_COLUMNS])

## 📌 Verifica se as células informadas estão livres e dentro do grid
func can_place(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if cell.x < 0 or cell.x >= GRID_ROWS:
			PrintLogManager.printlog(CLASS_NAME_LOG,
				PrintLogManager.LogType.DEBUG,
				"can_place bloqueado: linha fora do grid (%d)" % cell.x)
			return false
		if cell.y < 0 or cell.y >= GRID_COLUMNS:
			PrintLogManager.printlog(CLASS_NAME_LOG,
				PrintLogManager.LogType.DEBUG,
				"can_place bloqueado: coluna fora do grid (%d)" % cell.y)
			return false
		if grid[cell.x][cell.y] != 0:
			PrintLogManager.printlog(CLASS_NAME_LOG,
				PrintLogManager.LogType.DEBUG,
				"can_place bloqueado: célula ocupada em (%d,%d)" % [cell.x, cell.y])
			return false
	return true
