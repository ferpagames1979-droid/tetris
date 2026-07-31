extends Node

signal GameViewControllerSignal_piece_spawned(piece_type: PieceModel.PieceType)

signal GameViewControllerSignal_piece_locked(piece_type: PieceModel.PieceType, 
											cells : Array[Vector2i])
											
signal GameViewControllerSignal_piece_rotated(rotation_state : int)

signal GameViewControllerSignal_piece_moved(direction : Vector2i)

signal GameViewControllerSignal_game_over(total_lines_cleared : int, level : int)
