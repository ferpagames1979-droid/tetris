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
			return false
		if cell.y < 0 or cell.y >= GRID_COLUMNS:
			return false
		if grid[cell.x][cell.y] != 0:
			return false
	return true

## 📌 Retorna os índices de todas as linhas 100% preenchidas (nenhuma célula = 0)
func get_completed_rows() -> Array[int]:
	var completed_rows: Array[int] = []

	for row in range(GRID_ROWS):
		var is_row_full: bool = true
		for col in range(GRID_COLUMNS):
			if grid[row][col] == 0:
				is_row_full = false
				break
		if is_row_full:
			completed_rows.append(row)

	if completed_rows.size() > 0:
		PrintLogManager.printlog(CLASS_NAME_LOG,
			PrintLogManager.LogType.INFO,
			"Linhas completas detectadas: %s" % str(completed_rows))

	return completed_rows

## 📌 Remove as linhas informadas, aplica gravidade (desloca tudo acima pra baixo)
## e soma a quantidade removida em total_lines_cleared
func clear_rows(rows: Array[int]) -> void:
	if rows.is_empty():
		return

	var sorted_rows: Array[int] = rows.duplicate()
	sorted_rows.sort()
	sorted_rows.reverse()

	for row in sorted_rows:
		grid.remove_at(row)

	for i in range(rows.size()):
		var new_row: Array = []
		new_row.resize(GRID_COLUMNS)
		new_row.fill(0)
		grid.insert(0, new_row)

	total_lines_cleared += rows.size()

	PrintLogManager.printlog(CLASS_NAME_LOG,
		PrintLogManager.LogType.INFO,
		"%d linha(s) removida(s) — total_lines_cleared=%d" % [rows.size(), total_lines_cleared])
