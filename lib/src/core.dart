import 'package:collection/collection.dart';

import 'parsers.dart';

const BOARD_FILES = 8;
const BOARD_RANKS = 8;

const PIECE_COUNT_PER_PLAYER = {
  PieceType.pawn: 8,
  PieceType.knight: 2,
  PieceType.bishop: 2,
  PieceType.rook: 2,
  PieceType.queen: 1,
  PieceType.king: 1
};

enum Player {
  /// The white player, going from bottom to top.
  white(direction: 1),

  /// The black player, going from top to bottom.
  black(direction: -1);

  final int direction;

  const Player({required this.direction});

  Player get opposite => this == Player.white ? Player.black : Player.white;
}

class Coords {
  /// The file (x coordinate) of the position.
  ///
  /// A file value ranges from 1 (file A) to 8 (file H). Any other value indicates an unknown file.
  final int file;

  /// The rank (y coordinate) of the position.
  ///
  /// A rank value ranges from 1 (rank 1) to 8 (rank 8). Any other value indicates an unknown rank.
  final int rank;

  Coords(this.file, this.rank);

  /// Constructs a position from a string representation with unknown rank.
  Coords.file(String file) : this(file.codeUnitAt(0) - 96, 0);

  /// Constructs a position from a string representation with unknown file.
  Coords.rank(String rank) : this(0, rank.codeUnitAt(1) - 48);

  /// Constructs a position from a string representation.
  Coords.pos(String pos) : this(pos.codeUnitAt(0) - 96, pos.codeUnitAt(1) - 48);

  /// Whether the file is valid.
  bool get fileIsValid => 1 <= file && file <= BOARD_FILES;

  /// Whether the rank is valid.
  bool get rankIsValid => 1 <= rank && rank <= BOARD_RANKS;

  /// Whether the position is valid.
  bool get isValid => fileIsValid && rankIsValid;

  /// The index of the board tile corresponding to the current position.
  int get index {
    if (!isValid) {
      throw StateError('The tile index cannot be infered from invalid coordinates');
    }

    return (BOARD_RANKS - rank) * BOARD_FILES + (file - 1);
  }

  String get fileAsString => String.fromCharCode(file + 96);

  String get rankAsString => String.fromCharCode(rank + 48);

  String get posAsString => fileAsString + rankAsString;

  @override
  int get hashCode => Object.hash(file, rank);

  @override
  bool operator ==(Object other) {
    return other is Coords && other.file == file && other.rank == rank;
  }

  @override
  String toString() {
    return posAsString;
  }
}

enum Side { king, queen }

enum PieceType {
  pawn(name: 'p'),
  knight(name: 'n'),
  bishop(name: 'b'),
  rook(name: 'r'),
  queen(name: 'q'),
  king(name: 'k');

  final String name;

  const PieceType({required this.name});
}

class Piece {
  /// The piece type.
  final PieceType type;

  /// The piece player.
  final Player player;

  /// The new piece type if the piece has a promotion, null otherwise.
  final PieceType? promotion;

  Piece(this.type, this.player, {this.promotion});

  /// The actual piece type.
  PieceType get effectiveType => promotion ?? type;

  @override
  int get hashCode => Object.hash(type, player, promotion);

  @override
  bool operator ==(Object other) {
    return other is Piece &&
        other.type == type &&
        other.player == player &&
        other.promotion == promotion;
  }

  @override
  String toString() {
    return player == Player.white
        ? effectiveType.name.toUpperCase()
        : effectiveType.name.toLowerCase();
  }
}

class Tile {
  final Piece? piece;

  Tile(this.piece);

  /// Constructs an occupied tile.
  Tile.piece(PieceType type, Player player, {PieceType? promotion})
      : this(Piece(type, player, promotion: promotion));

  /// Constructs an empty tile.
  Tile.empty() : this(null);

  /// Whether the tile is empty.
  bool get isEmpty => piece == null;

  @override
  int get hashCode => Object.hash('tile', piece);

  @override
  bool operator ==(Object other) {
    return other is Tile && other.piece == piece;
  }

  @override
  String toString() {
    if (isEmpty) {
      return '.';
    }

    return piece.toString();
  }
}

class Board {
  static final Board initial =
      Board.fromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');

  /// The board tiles represented as a list.
  final List<Tile> tiles;

  /// The next player to move.
  final Player playerToMove;

  /// Whether the king castling is still available for the white player.
  final bool whiteKingCastlingAvailable;

  /// Whether the queen castling is still available for the white player.
  final bool whiteQueenCastlingAvailable;

  /// Whether the king castling is still available for the black player.
  final bool blackKingCastlingAvailable;

  /// Whether the queen castling is still available for the black player.
  final bool blackQueenCastlingAvailable;

  /// The "en passant" target tile if a pawn has performed a double forward move, null otherwise.
  final Coords? enPassantTarget;

  /// The number of halfmoves since the last capture or pawn advance.
  final int halfmoveClock;

  /// The number of full moves.
  final int fullmoveNumber;

  Board(this.tiles,
      {required this.playerToMove,
      required this.whiteKingCastlingAvailable,
      required this.whiteQueenCastlingAvailable,
      required this.blackKingCastlingAvailable,
      required this.blackQueenCastlingAvailable,
      required this.enPassantTarget,
      required this.halfmoveClock,
      required this.fullmoveNumber});

  factory Board.fromFEN(String fen) {
    final parser = FENParser();

    if (!parser.validate(fen)) {
      throw ArgumentError('Invalid or unsupported FEN format');
    }

    return parser.parse(fen);
  }

  String get FEN {
    final buffer = StringBuffer();

    for (var i = 0; i < BOARD_RANKS; i++) {
      var consecutiveEmptyTiles = 0;

      for (var j = 0; j < BOARD_FILES; j++) {
        final tile = tiles[i * BOARD_FILES + j];

        if (tile.isEmpty) {
          consecutiveEmptyTiles += 1;
        } else {
          if (consecutiveEmptyTiles > 0) {
            buffer.write(consecutiveEmptyTiles);
            consecutiveEmptyTiles = 0;
          }

          buffer.write(tile.piece!.toString());
        }
      }

      if (consecutiveEmptyTiles > 0) {
        buffer.write(consecutiveEmptyTiles);
      }

      if (i < BOARD_RANKS - 1) {
        buffer.write('/');
      }
    }

    buffer.write(' ');
    buffer.write(playerToMove == Player.white ? 'w' : 'b');
    buffer.write(' ');

    if (whiteKingCastlingAvailable ||
        whiteQueenCastlingAvailable ||
        blackKingCastlingAvailable ||
        blackQueenCastlingAvailable) {
      if (whiteKingCastlingAvailable) {
        buffer.write('K');
      }

      if (whiteQueenCastlingAvailable) {
        buffer.write('Q');
      }

      if (blackKingCastlingAvailable) {
        buffer.write('k');
      }

      if (blackQueenCastlingAvailable) {
        buffer.write('q');
      }
    } else {
      buffer.write('-');
    }

    buffer.write(' ');

    if (enPassantTarget == null) {
      buffer.write('-');
    } else {
      buffer.write(enPassantTarget!.posAsString);
    }

    buffer.write(' ');
    buffer.write(halfmoveClock);
    buffer.write(' ');
    buffer.write(fullmoveNumber);

    return buffer.toString();
  }

  /// The pieces of the white player.
  Map<PieceType, int> get whitePieces => _pieces(Player.white);

  /// The pieces of the black player.
  Map<PieceType, int> get blackPieces => _pieces(Player.black);

  /// The pieces captured by the white player.
  Map<PieceType, int> get whiteCapturedPieces => _capturedPieces(Player.white);

  /// The pieces captured by the black player.
  Map<PieceType, int> get blackCapturedPieces => _capturedPieces(Player.black);

  /// Computes each piece count for player [player].
  Map<PieceType, int> _pieces(Player player) {
    return tiles.fold({}, (map, tile) {
      if (!tile.isEmpty && tile.piece!.player == player) {
        map[tile.piece!.type] = (map[tile.piece!.type] ?? 0) + 1;
      }

      return map;
    });
  }

  /// Computes the amount of pieces captured by player [player].
  Map<PieceType, int> _capturedPieces(Player player) {
    final pieces = _pieces(player.opposite);

    return PieceType.values.fold({}, (map, type) {
      if (PIECE_COUNT_PER_PLAYER.containsKey(type) && pieces.containsKey(type)) {
        map[type] = PIECE_COUNT_PER_PLAYER[type]! - pieces[type]!;
      }

      return map;
    });
  }

  /// Whether there is a piece of effective type [type] owned by player [player] at position
  /// [coords].
  ///
  /// The type and the player can be omitted. In this case, it just checks whether there is a piece
  /// at position [coords].
  bool has(Coords coords, {PieceType? type, Player? player}) {
    var piece = tiles[coords.index].piece;

    if (piece == null) {
      return false;
    }

    var present = true;

    if (type != null) {
      present = present && piece.effectiveType == type;
    }

    if (player != null) {
      present = present && piece.player == player;
    }

    return present;
  }

  /// Moves a piece from position [from] to position [to].
  ///
  /// Optionally, the piece can be promoted to type [promotion], and it can capture another piece at
  /// position [capture]. Note that the positions [to] and [capture] may be different, in order to
  /// allow "en passant" captures.
  Board move(Coords from, Coords to, {PieceType? promotion, Coords? capture}) {
    if (!has(from)) {
      throw StateError('There is no piece to move from $from');
    }

    if (to != capture && has(to)) {
      throw StateError('There is already a piece on $to');
    }

    if (capture != null && !has(capture)) {
      throw StateError('There is no piece to capture on $capture');
    }

    final List<Tile> newTiles = List.from(tiles);

    final piece = tiles[from.index].piece!;

    newTiles[from.index] = Tile.empty();
    newTiles[to.index] = Tile.piece(piece.type, piece.player, promotion: promotion);

    if (capture != null && capture != to) {
      // If the captured piece is NOT on the destination tile of the capturing piece, remove the
      // captured piece (e.g., pawn "en passant" capture).
      newTiles[capture.index] = Tile.empty();
    }

    // Detect if castling is still available after the move.
    var newWhiteKingCastlingAvailable = whiteKingCastlingAvailable;
    var newWhiteQueenCastlingAvailable = whiteQueenCastlingAvailable;
    var newBlackKingCastlingAvailable = blackKingCastlingAvailable;
    var newBlackQueenCastlingAvailable = blackQueenCastlingAvailable;

    if (piece.effectiveType == PieceType.king) {
      if (piece.player == Player.white) {
        newWhiteKingCastlingAvailable = false;
        newWhiteQueenCastlingAvailable = false;
      } else {
        newBlackKingCastlingAvailable = false;
        newBlackQueenCastlingAvailable = false;
      }
    } else if (piece.effectiveType == PieceType.rook) {
      if (piece.player == Player.white) {
        if (from.posAsString == 'h1') {
          newWhiteKingCastlingAvailable = false;
        } else if (from.posAsString == 'a1') {
          newWhiteQueenCastlingAvailable = false;
        }
      } else {
        if (from.posAsString == 'h8') {
          newBlackKingCastlingAvailable = false;
        } else if (from.posAsString == 'a8') {
          newBlackQueenCastlingAvailable = false;
        }
      }
    }

    // Detect if an "en passant" target tile is present.
    var newEnPassantTarget = enPassantTarget;

    if (piece.effectiveType == PieceType.pawn && (to.rank - from.rank).abs() == 2) {
      newEnPassantTarget = Coords(to.file, to.rank - piece.player.direction);
    } else {
      newEnPassantTarget = null;
    }

    // If the move is a capture or a pawn action, reset the halfmove clock; otherwise, increment the
    // halfmove clock.
    final newHalfmoveClock =
        (capture != null || piece.effectiveType == PieceType.pawn) ? 0 : halfmoveClock + 1;

    // If the move is performed by the black player, then a full move has been performed.
    final newFullmoveNumber = piece.player == Player.black ? fullmoveNumber + 1 : fullmoveNumber;

    return Board(newTiles,
        playerToMove: piece.player.opposite,
        whiteKingCastlingAvailable: newWhiteKingCastlingAvailable,
        whiteQueenCastlingAvailable: newWhiteQueenCastlingAvailable,
        blackKingCastlingAvailable: newBlackKingCastlingAvailable,
        blackQueenCastlingAvailable: newBlackQueenCastlingAvailable,
        enPassantTarget: newEnPassantTarget,
        halfmoveClock: newHalfmoveClock,
        fullmoveNumber: newFullmoveNumber);
  }

  /// Performs a castling move for player [player] on side [side].
  Board castle(Player player, Side side) {
    final List<Tile> newTiles = List.from(tiles);

    switch ((player, side)) {
      case (Player.white, Side.king):
        {
          newTiles[Coords.pos('e1').index] = Tile.empty();
          newTiles[Coords.pos('f1').index] = Tile.piece(PieceType.rook, player);
          newTiles[Coords.pos('g1').index] = Tile.piece(PieceType.king, player);
          newTiles[Coords.pos('h1').index] = Tile.empty();
        }
      case (Player.white, Side.queen):
        {
          newTiles[Coords.pos('e1').index] = Tile.empty();
          newTiles[Coords.pos('d1').index] = Tile.piece(PieceType.rook, player);
          newTiles[Coords.pos('c1').index] = Tile.piece(PieceType.king, player);
          newTiles[Coords.pos('a1').index] = Tile.empty();
        }
      case (Player.black, Side.king):
        {
          newTiles[Coords.pos('e8').index] = Tile.empty();
          newTiles[Coords.pos('f8').index] = Tile.piece(PieceType.rook, player);
          newTiles[Coords.pos('g8').index] = Tile.piece(PieceType.king, player);
          newTiles[Coords.pos('h8').index] = Tile.empty();
        }
      case (Player.black, Side.queen):
        {
          newTiles[Coords.pos('e8').index] = Tile.empty();
          newTiles[Coords.pos('d8').index] = Tile.piece(PieceType.rook, player);
          newTiles[Coords.pos('c8').index] = Tile.piece(PieceType.king, player);
          newTiles[Coords.pos('a8').index] = Tile.empty();
        }
    }

    // Remove castling availability for the current player.
    var newWhiteKingCastlingAvailable = whiteKingCastlingAvailable;
    var newWhiteQueenCastlingAvailable = whiteQueenCastlingAvailable;
    var newBlackKingCastlingAvailable = blackKingCastlingAvailable;
    var newBlackQueenCastlingAvailable = blackQueenCastlingAvailable;

    if (player == Player.white) {
      newWhiteKingCastlingAvailable = false;
      newWhiteQueenCastlingAvailable = false;
    } else {
      newBlackKingCastlingAvailable = false;
      newBlackQueenCastlingAvailable = false;
    }

    // The halfmove clock increases anyway.
    final newHalfmoveClock = halfmoveClock + 1;

    // If the move is performed by the black player, then a full move has been performed.
    final newFullmoveNumber = player == Player.black ? fullmoveNumber + 1 : fullmoveNumber;

    return Board(newTiles,
        playerToMove: player.opposite,
        whiteKingCastlingAvailable: newWhiteKingCastlingAvailable,
        whiteQueenCastlingAvailable: newWhiteQueenCastlingAvailable,
        blackKingCastlingAvailable: newBlackKingCastlingAvailable,
        blackQueenCastlingAvailable: newBlackQueenCastlingAvailable,
        enPassantTarget: null, // Reset the "en passant" target.
        halfmoveClock: newHalfmoveClock,
        fullmoveNumber: newFullmoveNumber);
  }

  /// Computes the current positions of the pawns owned by player [player] and able to get to
  /// position [coords] by a single forward move.
  List<Coords> originForPawnSingleMove(Coords coords, Player player) {
    final origin = [Coords(coords.file, coords.rank - player.direction)];

    return origin
        .where((coords) => coords.isValid && has(coords, type: PieceType.pawn, player: player))
        .toList();
  }

  /// Computes the current positions of the pawns owned by player [player] and able to get to
  /// position [coords] by a double forward move.
  List<Coords> originForPawnDoubleMove(Coords coords, Player player) {
    final origin = [Coords(coords.file, coords.rank - 2 * player.direction)];

    return origin
        .where((coords) => coords.isValid && has(coords, type: PieceType.pawn, player: player))
        .toList();
  }

  /// Computes the current positions of the pawns owned by player [player] and able to get to
  /// position [coords] by a capture move.
  List<Coords> originForPawnCapture(Coords coords, Player player) {
    final origin = [
      Coords(coords.file - 1, coords.rank - player.direction),
      Coords(coords.file + 1, coords.rank - player.direction)
    ];

    return origin
        .where((coords) => coords.isValid && has(coords, type: PieceType.pawn, player: player))
        .toList();
  }

  /// Computes the current positions of the knights owned by player [player] and able to get to
  /// position [coords] by a normal or capture move.
  List<Coords> originForKnightMove(Coords coords, Player player) {
    final origin = [
      Coords(coords.file + 1, coords.rank + 2),
      Coords(coords.file + 2, coords.rank + 1),
      Coords(coords.file + 1, coords.rank - 2),
      Coords(coords.file + 2, coords.rank - 1),
      Coords(coords.file - 1, coords.rank + 2),
      Coords(coords.file - 2, coords.rank + 1),
      Coords(coords.file - 1, coords.rank - 2),
      Coords(coords.file - 2, coords.rank - 1)
    ];

    return origin
        .where((coords) => coords.isValid && has(coords, type: PieceType.knight, player: player))
        .toList();
  }

  /// Computes the current positions of the bishops owned by player [player] and able to get to
  /// position [coords] by a normal or capture move.
  List<Coords> originForBishopMove(Coords coords, Player player) {
    final origin = <Coords>[];

    Coords current;

    // scan up-right
    current = coords;
    do {
      current = Coords(current.file + 1, current.rank + 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan down-right
    current = coords;
    do {
      current = Coords(current.file + 1, current.rank - 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan up-left
    current = coords;
    do {
      current = Coords(current.file - 1, current.rank + 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan down-left
    current = coords;
    do {
      current = Coords(current.file - 1, current.rank - 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    return origin
        .where((coords) => coords.isValid && has(coords, type: PieceType.bishop, player: player))
        .toList();
  }

  /// Computes the current positions of the rooks owned by player [player] and able to get to
  /// position [coords] by a normal or capture move.
  List<Coords> originForRookMove(Coords coords, Player player) {
    final origin = <Coords>[];

    Coords current;

    // scan up
    current = coords;
    do {
      current = Coords(current.file, current.rank + 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan down
    current = coords;
    do {
      current = Coords(current.file, current.rank - 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan left
    current = coords;
    do {
      current = Coords(current.file - 1, current.rank);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan right
    current = coords;
    do {
      current = Coords(current.file + 1, current.rank);
    } while (current.isValid && !has(current));
    origin.add(current);

    return origin
        .where((coords) => coords.isValid && has(coords, type: PieceType.rook, player: player))
        .toList();
  }

  /// Computes the current positions of the queens owned by player [player] and able to get to
  /// position [coords] by a normal or capture move.
  List<Coords> originForQueenMove(Coords coords, Player player) {
    final origin = <Coords>[];

    Coords current;

    // scan up-right
    current = coords;
    do {
      current = Coords(current.file + 1, current.rank + 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan down-right
    current = coords;
    do {
      current = Coords(current.file + 1, current.rank - 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan up-left
    current = coords;
    do {
      current = Coords(current.file - 1, current.rank + 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan down-left
    current = coords;
    do {
      current = Coords(current.file - 1, current.rank - 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan up
    current = coords;
    do {
      current = Coords(current.file, current.rank + 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan down
    current = coords;
    do {
      current = Coords(current.file, current.rank - 1);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan left
    current = coords;
    do {
      current = Coords(current.file - 1, current.rank);
    } while (current.isValid && !has(current));
    origin.add(current);

    // scan right
    current = coords;
    do {
      current = Coords(current.file + 1, current.rank);
    } while (current.isValid && !has(current));
    origin.add(current);

    return origin
        .where((coords) => coords.isValid && has(coords, type: PieceType.queen, player: player))
        .toList();
  }

  /// Computes the current positions of the kings owned by player [player] and able to get to
  /// position [coords] by a normal or capture move.
  List<Coords> originForKingMove(Coords coords, Player player) {
    final origin = [
      Coords(coords.file, coords.rank + 1),
      Coords(coords.file + 1, coords.rank + 1),
      Coords(coords.file + 1, coords.rank),
      Coords(coords.file + 1, coords.rank - 1),
      Coords(coords.file, coords.rank - 1),
      Coords(coords.file - 1, coords.rank - 1),
      Coords(coords.file - 1, coords.rank),
      Coords(coords.file - 1, coords.rank + 1),
    ];

    return origin
        .where((coords) => coords.isValid && has(coords, type: PieceType.king, player: player))
        .toList();
  }

  String _capturedPieceString(Player player, PieceType type) {
    final capturedPieces = player == Player.white ? whiteCapturedPieces : blackCapturedPieces;
    final pieceName = player == Player.white ? type.name.toLowerCase() : type.name.toUpperCase();
    final pieceCount = capturedPieces[type] ?? '0';

    return '$pieceName=$pieceCount';
  }

  String _capturedPiecesString(Player player) {
    return PieceType.values
        .where((type) => type != PieceType.king)
        .map((type) => _capturedPieceString(player, type))
        .join(', ');
  }

  @override
  int get hashCode => Object.hash(
      const ListEquality().hash(tiles),
      playerToMove,
      whiteKingCastlingAvailable,
      whiteQueenCastlingAvailable,
      blackKingCastlingAvailable,
      blackQueenCastlingAvailable,
      enPassantTarget,
      halfmoveClock,
      fullmoveNumber);

  @override
  bool operator ==(Object other) {
    return other is Board &&
        const ListEquality().equals(other.tiles, tiles) &&
        other.playerToMove == playerToMove &&
        other.whiteKingCastlingAvailable == whiteKingCastlingAvailable &&
        other.whiteQueenCastlingAvailable == whiteQueenCastlingAvailable &&
        other.blackKingCastlingAvailable == blackKingCastlingAvailable &&
        other.blackQueenCastlingAvailable == blackQueenCastlingAvailable &&
        other.enPassantTarget == enPassantTarget &&
        other.halfmoveClock == halfmoveClock &&
        other.fullmoveNumber == fullmoveNumber;
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.writeln('Player to move: $playerToMove');
    buffer.writeln('White king castling: $whiteKingCastlingAvailable');
    buffer.writeln('White queen castling: $whiteQueenCastlingAvailable');
    buffer.writeln('Black king castling: $blackKingCastlingAvailable');
    buffer.writeln('Black queen castling: $blackQueenCastlingAvailable');
    buffer.writeln('En passant target: $enPassantTarget');
    buffer.writeln('Halfmove clock: $halfmoveClock');
    buffer.writeln('Full move number: $fullmoveNumber');

    buffer.writeln(_capturedPiecesString(Player.black));

    for (var i = 0; i < 8; i++) {
      for (var j = 0; j < 8; j++) {
        buffer.write(tiles[i * 8 + j].toString());
        buffer.write(" ");
      }

      buffer.write("\n");
    }

    buffer.writeln(_capturedPiecesString(Player.white));

    return buffer.toString();
  }
}
