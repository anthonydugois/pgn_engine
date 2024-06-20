import 'package:pgn_engine/src/core.dart';
import 'package:test/test.dart';

void main() {
  test('Constructs Board instance from FEN definition', () {
    expect(
        Board.fromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'),
        equals(Board([
          Tile.piece(PieceType.rook, Player.black),
          Tile.piece(PieceType.knight, Player.black),
          Tile.piece(PieceType.bishop, Player.black),
          Tile.piece(PieceType.queen, Player.black),
          Tile.piece(PieceType.king, Player.black),
          Tile.piece(PieceType.bishop, Player.black),
          Tile.piece(PieceType.knight, Player.black),
          Tile.piece(PieceType.rook, Player.black),
          ...List.generate(8, (int index) => Tile.piece(PieceType.pawn, Player.black)),
          ...List.generate(32, (int index) => Tile.empty()),
          ...List.generate(8, (int index) => Tile.piece(PieceType.pawn, Player.white)),
          Tile.piece(PieceType.rook, Player.white),
          Tile.piece(PieceType.knight, Player.white),
          Tile.piece(PieceType.bishop, Player.white),
          Tile.piece(PieceType.queen, Player.white),
          Tile.piece(PieceType.king, Player.white),
          Tile.piece(PieceType.bishop, Player.white),
          Tile.piece(PieceType.knight, Player.white),
          Tile.piece(PieceType.rook, Player.white),
        ],
            playerToMove: Player.white,
            whiteKingCastlingAvailable: true,
            whiteQueenCastlingAvailable: true,
            blackKingCastlingAvailable: true,
            blackQueenCastlingAvailable: true,
            enPassantTarget: null,
            halfmoveClock: 0,
            fullmoveNumber: 1)));
  });
}
