import 'core.dart';

/// The memory representation of a standard move.
///
/// A move always includes the following information:
/// - the player initiating the move;
/// - the type of the moved piece;
/// - the initial position of the moved piece (possibly null if it can be inferred later);
/// - the final position of the moved piece (possibly null if it is implicit, e.g., for castling);
/// - whether there is a check;
/// - whether there is a checkmate;
/// - some additional metadata (possibly empty).
abstract class Move {
  final Player player;
  final PieceType type;

  final Coords? _from;
  final Coords? _to;

  final bool check;
  final bool checkmate;
  final String meta;

  Move(this.player, this.type, this._from, this._to,
      {this.check = false, this.checkmate = false, this.meta = ''});

  Board execute(Board board);

  Coords computeFromPosition(Board board);

  Coords computeToPosition(Board board);

  Coords _selectOriginWithFile(Coords from, List<Coords> origin) {
    assert(origin.length == 2);
    assert(from.fileIsValid);

    Coords uniqueOrigin;

    if (origin[0].file == origin[1].file) {
      // Possible ambiguity: the two origins have the same file.
      if (!from.rankIsValid) {
        throw StateError('Ambiguity: origins have the same file and no rank is provided');
      }

      if (origin[0].rank == origin[1].rank) {
        throw StateError('There are two identical origins');
      }

      // Discriminate according to rank.
      if (from.rank == origin[0].rank) {
        uniqueOrigin = origin[0];
      } else if (from.rank == origin[1].rank) {
        uniqueOrigin = origin[1];
      } else {
        throw StateError('Cannot decide which piece must be moved to $_to');
      }
    } else {
      // No ambiguity: discriminate according to file.
      if (from.file == origin[0].file) {
        uniqueOrigin = origin[0];
      } else if (from.file == origin[1].file) {
        uniqueOrigin = origin[1];
      } else {
        throw StateError('Cannot decide which piece must be moved to $_to');
      }
    }

    return uniqueOrigin;
  }

  Coords _selectOriginWithRank(Coords from, List<Coords> origin) {
    assert(origin.length == 2);
    assert(from.rankIsValid);

    Coords uniqueOrigin;

    if (origin[0].rank == origin[1].rank) {
      // Possible ambiguity: the two origins have the same rank.
      if (!from.fileIsValid) {
        throw StateError('Ambiguity: origins have the same rank and no file is provided');
      }

      if (origin[0].file == origin[1].file) {
        throw StateError('There are two identical origins');
      }

      // Discriminate according to file.
      if (from.file == origin[0].file) {
        uniqueOrigin = origin[0];
      } else if (from.file == origin[1].file) {
        uniqueOrigin = origin[1];
      } else {
        throw StateError('Cannot decide which piece must be moved to $_to');
      }
    } else {
      // No ambiguity: discriminate according to rank.
      if (from.rank == origin[0].rank) {
        uniqueOrigin = origin[0];
      } else if (from.rank == origin[1].rank) {
        uniqueOrigin = origin[1];
      } else {
        throw StateError('Cannot decide which piece must be moved to $_to');
      }
    }

    return uniqueOrigin;
  }

  Coords _selectOrigin(List<Coords> origin) {
    if (origin.length == 0) {
      throw StateError('No piece can be moved to $_to');
    }

    if (origin.length > 2) {
      throw StateError('Fatal error: too much pieces');
    }

    Coords uniqueOrigin;

    if (origin.length == 1) {
      // Only one possible origin; there is no ambiguity.
      uniqueOrigin = origin[0];
    } else {
      // Two possible origins; we must remove ambiguity according to additional information we have
      // on the move.
      if (_from == null || (!_from.fileIsValid && !_from.rankIsValid)) {
        throw StateError('There is no indication to remove the ambiguity');
      }

      if (_from.fileIsValid) {
        // Try to discriminate according to file.
        uniqueOrigin = _selectOriginWithFile(_from, origin);
      } else {
        // Try to discriminate according to rank.
        uniqueOrigin = _selectOriginWithRank(_from, origin);
      }
    }

    return uniqueOrigin;
  }
}

class PawnSingleMove extends Move {
  final PieceType? promotion;

  PawnSingleMove(Player player, Coords? from, Coords? to,
      {bool check = false, bool checkmate = false, String meta = '', this.promotion})
      : super(player, PieceType.pawn, from, to, check: check, checkmate: checkmate, meta: meta);

  @override
  Coords computeFromPosition(Board board) {
    final to = computeToPosition(board);
    final origin = board.originForPawnSingleMove(to, player);

    return _selectOrigin(origin);
  }

  @override
  Coords computeToPosition(Board board) {
    if (_to == null) {
      throw StateError('There is no destination for this move');
    }

    return _to;
  }

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    return board.move(from, to, promotion: promotion);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write(_to.toString());

    if (promotion != null) {
      buffer.write('=');
      buffer.write(promotion.toString());
    }

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class PawnDoubleMove extends Move {
  PawnDoubleMove(Player player, Coords? from, Coords? to,
      {bool check = false, bool checkmate = false, String meta = ''})
      : super(player, PieceType.pawn, from, to, check: check, checkmate: checkmate, meta: meta);

  @override
  Coords computeFromPosition(Board board) {
    final to = computeToPosition(board);
    final origin = board.originForPawnDoubleMove(to, player);

    return _selectOrigin(origin);
  }

  @override
  Coords computeToPosition(Board board) {
    if (_to == null) {
      throw StateError('There is no destination for this move');
    }

    return _to;
  }

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    return board.move(from, to);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class PawnCapture extends Move {
  final PieceType? promotion;

  PawnCapture(Player player, Coords? from, Coords? to,
      {bool check = false, bool checkmate = false, String meta = '', this.promotion})
      : super(player, PieceType.pawn, from, to, check: check, checkmate: checkmate, meta: meta);

  @override
  Coords computeFromPosition(Board board) {
    final to = computeToPosition(board);
    final origin = board.originForPawnCapture(to, player);

    return _selectOrigin(origin);
  }

  @override
  Coords computeToPosition(Board board) {
    if (_to == null) {
      throw StateError('There is no destination for this move');
    }

    return _to;
  }

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    if (board.has(to, player: player.opposite)) {
      // This is a simple capture of *any piece* (pawn can be promoted).
      return board.move(from, to, promotion: promotion, capture: to);
    } else if (to == board.enPassantTarget) {
      // This is an "en passant" capture of *a pawn* (no promotion is possible).
      final capture = Coords(to.file, to.rank - player.direction);

      if (board.has(capture, type: PieceType.pawn, player: player.opposite)) {
        return board.move(from, to, capture: capture);
      }
    }

    throw StateError('There is no piece to capture by moving to $to');
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    if (_from != null) {
      buffer.write(_from.fileAsString);
    }

    buffer.write('x');
    buffer.write(_to.toString());

    if (promotion != null) {
      buffer.write('=');
      buffer.write(promotion.toString());
    }

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class KnightMove extends Move {
  KnightMove(Player player, Coords? from, Coords? to,
      {bool check = false, bool checkmate = false, String meta = ''})
      : super(player, PieceType.knight, from, to, check: check, checkmate: checkmate, meta: meta);

  @override
  Coords computeFromPosition(Board board) {
    final to = computeToPosition(board);
    final origin = board.originForKnightMove(to, player);

    return _selectOrigin(origin);
  }

  @override
  Coords computeToPosition(Board board) {
    if (_to == null) {
      throw StateError('There is no destination for this move');
    }

    return _to;
  }

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    return board.move(from, to);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('N');

    if (_from != null) {
      if (_from.fileIsValid) {
        buffer.write(_from.fileAsString);
      }

      if (_from.rankIsValid) {
        buffer.write(_from.rankAsString);
      }
    }

    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class KnightCapture extends KnightMove {
  KnightCapture(super.player, super.from, super.to,
      {super.check = false, super.checkmate = false, super.meta = ''});

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    if (board.has(to, player: player.opposite)) {
      return board.move(from, to, capture: to);
    }

    throw StateError('There is no piece to capture by moving to $to');
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('N');

    if (_from != null) {
      if (_from.fileIsValid) {
        buffer.write(_from.fileAsString);
      }

      if (_from.rankIsValid) {
        buffer.write(_from.rankAsString);
      }
    }

    buffer.write('x');
    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class BishopMove extends Move {
  BishopMove(Player player, Coords? from, Coords? to,
      {bool check = false, bool checkmate = false, String meta = ''})
      : super(player, PieceType.bishop, from, to, check: check, checkmate: checkmate, meta: meta);

  @override
  Coords computeFromPosition(Board board) {
    final to = computeToPosition(board);
    final origin = board.originForBishopMove(to, player);

    return _selectOrigin(origin);
  }

  @override
  Coords computeToPosition(Board board) {
    if (_to == null) {
      throw StateError('There is no destination for this move');
    }

    return _to;
  }

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    return board.move(from, to);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('B');

    if (_from != null) {
      if (_from.fileIsValid) {
        buffer.write(_from.fileAsString);
      }

      if (_from.rankIsValid) {
        buffer.write(_from.rankAsString);
      }
    }

    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class BishopCapture extends BishopMove {
  BishopCapture(super.player, super.from, super.to,
      {super.check = false, super.checkmate = false, super.meta = ''});

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    if (board.has(to, player: player.opposite)) {
      return board.move(from, to, capture: to);
    }

    throw StateError('There is no piece to capture by moving to $to');
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('B');

    if (_from != null) {
      if (_from.fileIsValid) {
        buffer.write(_from.fileAsString);
      }

      if (_from.rankIsValid) {
        buffer.write(_from.rankAsString);
      }
    }

    buffer.write('x');
    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class RookMove extends Move {
  RookMove(Player player, Coords? from, Coords? to,
      {bool check = false, bool checkmate = false, String meta = ''})
      : super(player, PieceType.rook, from, to, check: check, checkmate: checkmate, meta: meta);

  @override
  Coords computeFromPosition(Board board) {
    final to = computeToPosition(board);
    final origin = board.originForRookMove(to, player);

    return _selectOrigin(origin);
  }

  @override
  Coords computeToPosition(Board board) {
    if (_to == null) {
      throw StateError('There is no destination for this move');
    }

    return _to;
  }

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    return board.move(from, to);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('R');

    if (_from != null) {
      if (_from.fileIsValid) {
        buffer.write(_from.fileAsString);
      }

      if (_from.rankIsValid) {
        buffer.write(_from.rankAsString);
      }
    }

    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class RookCapture extends RookMove {
  RookCapture(super.player, super.from, super.to,
      {super.check = false, super.checkmate = false, super.meta = ''});

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    if (board.has(to, player: player.opposite)) {
      return board.move(from, to, capture: to);
    }

    throw StateError('There is no piece to capture by moving to $to');
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('R');

    if (_from != null) {
      if (_from.fileIsValid) {
        buffer.write(_from.fileAsString);
      }

      if (_from.rankIsValid) {
        buffer.write(_from.rankAsString);
      }
    }

    buffer.write('x');
    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class QueenMove extends Move {
  QueenMove(Player player, Coords? from, Coords? to,
      {bool check = false, bool checkmate = false, String meta = ''})
      : super(player, PieceType.queen, from, to, check: check, checkmate: checkmate, meta: meta);

  @override
  Coords computeFromPosition(Board board) {
    final to = computeToPosition(board);
    final origin = board.originForQueenMove(to, player);

    return _selectOrigin(origin);
  }

  @override
  Coords computeToPosition(Board board) {
    if (_to == null) {
      throw StateError('There is no destination for this move');
    }

    return _to;
  }

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    return board.move(from, to);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('Q');
    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class QueenCapture extends QueenMove {
  QueenCapture(super.player, super.from, super.to,
      {super.check = false, super.checkmate = false, super.meta = ''});

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    if (board.has(to, player: player.opposite)) {
      return board.move(from, to, capture: to);
    }

    throw StateError('There is no piece to capture by moving to $to');
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('Qx');
    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class KingMove extends Move {
  KingMove(Player player, Coords? from, Coords? to,
      {bool check = false, bool checkmate = false, String meta = ''})
      : super(player, PieceType.king, from, to, check: check, checkmate: checkmate, meta: meta);

  @override
  Coords computeFromPosition(Board board) {
    final to = computeToPosition(board);
    final origin = board.originForKingMove(to, player);

    return _selectOrigin(origin);
  }

  @override
  Coords computeToPosition(Board board) {
    if (_to == null) {
      throw StateError('There is no destination for this move');
    }

    return _to;
  }

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    return board.move(from, to);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('K');
    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class KingCapture extends KingMove {
  KingCapture(super.player, super.from, super.to,
      {super.check = false, super.checkmate = false, super.meta = ''});

  @override
  Board execute(Board board) {
    final from = computeFromPosition(board);
    final to = computeToPosition(board);

    if (board.has(to, player: player.opposite)) {
      return board.move(from, to, capture: to);
    }

    throw StateError('There is no piece to capture by moving to $to');
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('Kx');
    buffer.write(_to.toString());

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class KingKingCastling extends KingMove {
  KingKingCastling(super.player, super.from, super.to,
      {super.check = false, super.checkmate = false, super.meta = ''});

  @override
  Coords computeFromPosition(Board board) {
    return player == Player.white ? Coords.pos('e1') : Coords.pos('e8');
  }

  @override
  Coords computeToPosition(Board board) {
    return player == Player.white ? Coords.pos('g1') : Coords.pos('g8');
  }

  @override
  Board execute(Board board) {
    return board.castle(player, Side.king);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('O-O');

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}

class KingQueenCastling extends KingMove {
  KingQueenCastling(super.player, super.from, super.to,
      {super.check = false, super.checkmate = false, super.meta = ''});

  @override
  Coords computeFromPosition(Board board) {
    return player == Player.white ? Coords.pos('e1') : Coords.pos('e8');
  }

  @override
  Coords computeToPosition(Board board) {
    return player == Player.white ? Coords.pos('c1') : Coords.pos('c8');
  }

  @override
  Board execute(Board board) {
    return board.castle(player, Side.queen);
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.write('O-O-O');

    if (checkmate) {
      buffer.write('#');
    } else if (check) {
      buffer.write('+');
    }

    return buffer.toString();
  }
}
