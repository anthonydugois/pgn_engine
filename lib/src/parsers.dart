import 'core.dart';
import 'moves.dart';
import 'game.dart';

abstract interface class Parser<T> {
  T parse(String str);
}

class FENParser implements Parser<Board> {
  static final _rowRE = r'[pnbrqkPNBRQK1-8]{1,8}';
  static final _boardRE = r'(?<board>(?:' + _rowRE + r'/){7}' + _rowRE + r')';
  static final _playerRE = r'(?<player>[wb])';
  static final _castleRE = r'(?<castle>(?:K?Q?k?q?)|-)';
  static final _enPassantRE = r'(?<ep>(?:[a-h][36])|-)';
  static final _halfmoveRE = r'(?<hm>[0-9]+)';
  static final _fullmoveRE = r'(?<fm>[1-9][0-9]*)';
  static final _fenRE = _boardRE +
      r' ' +
      _playerRE +
      r' ' +
      _castleRE +
      r' ' +
      _enPassantRE +
      r' ' +
      _halfmoveRE +
      r' ' +
      _fullmoveRE;

  static final fenRegExp = RegExp(_fenRE);

  final _boardParser = BoardParser();

  /// Whether the provided FEN string [fen] has a valid and supported format.
  bool validate(String fen) {
    return fenRegExp.hasMatch(fen);
  }

  @override
  Board parse(String fen) {
    final match = fenRegExp.firstMatch(fen);

    if (match == null) {
      throw ArgumentError('The provided string is not in a valid or supported FEN format');
    }

    final rawBoard = match.namedGroup('board');
    final rawPlayer = match.namedGroup('player');
    final rawCastle = match.namedGroup('castle');
    final rawEnPassant = match.namedGroup('ep');
    final rawHalfmove = match.namedGroup('hm');
    final rawFullmove = match.namedGroup('fm');

    if (rawBoard == null) {
      throw StateError('No valid board definition found in the FEN string');
    }

    final tiles = _boardParser.parse(rawBoard);

    if (rawPlayer == null) {
      throw StateError('No valid player definition found in the FEN string');
    }

    final playerToMove = rawPlayer == 'w' ? Player.white : Player.black;

    if (rawCastle == null) {
      throw StateError('No valid castling availability definition found in the FEN string');
    }

    final whiteKingCastlingAvailable = rawCastle.contains('K');
    final whiteQueenCastlingAvailable = rawCastle.contains('Q');
    final blackKingCastlingAvailable = rawCastle.contains('k');
    final blackQueenCastlingAvailable = rawCastle.contains('q');

    if (rawEnPassant == null) {
      throw StateError('No valid "en passant" target definition found in the FEN string');
    }

    final enPassantTarget = rawEnPassant == '-' ? null : Coords.pos(rawEnPassant);

    if (rawHalfmove == null) {
      throw StateError('No valid halfmove clock definition found in the FEN string');
    }

    final halfmoveClock = int.parse(rawHalfmove);

    if (rawFullmove == null) {
      throw StateError('No valid full move number definition found in the FEN string');
    }

    final fullmoveNumber = int.parse(rawFullmove);

    return Board(tiles,
        playerToMove: playerToMove,
        whiteKingCastlingAvailable: whiteKingCastlingAvailable,
        whiteQueenCastlingAvailable: whiteQueenCastlingAvailable,
        blackKingCastlingAvailable: blackKingCastlingAvailable,
        blackQueenCastlingAvailable: blackQueenCastlingAvailable,
        enPassantTarget: enPassantTarget,
        halfmoveClock: halfmoveClock,
        fullmoveNumber: fullmoveNumber);
  }
}

class BoardParser implements Parser<List<Tile>> {
  static final _rowRE = r'([pnbrqkPNBRQK1-8]{1,8})';

  static final rowRegExp = RegExp(_rowRE);

  @override
  List<Tile> parse(String fenBoard) {
    final tiles = <Tile>[];

    for (final match in rowRegExp.allMatches(fenBoard)) {
      final rawRow = match.group(0);

      if (rawRow == null) {
        throw StateError('Invalid row');
      }

      final row = <Tile>[];

      for (var i = 0; i < rawRow.length; i++) {
        final char = rawRow[i];

        switch (char) {
          case '1' || '2' || '3' || '4' || '5' || '6' || '7' || '8':
            {
              final n = int.parse(char);

              for (var j = 0; j < n; j++) {
                row.add(Tile.empty());
              }
            }
          case 'p':
            {
              row.add(Tile.piece(PieceType.pawn, Player.black));
            }
          case 'n':
            {
              row.add(Tile.piece(PieceType.knight, Player.black));
            }
          case 'b':
            {
              row.add(Tile.piece(PieceType.bishop, Player.black));
            }
          case 'r':
            {
              row.add(Tile.piece(PieceType.rook, Player.black));
            }
          case 'q':
            {
              row.add(Tile.piece(PieceType.queen, Player.black));
            }
          case 'k':
            {
              row.add(Tile.piece(PieceType.king, Player.black));
            }
          case 'P':
            {
              row.add(Tile.piece(PieceType.pawn, Player.white));
            }
          case 'N':
            {
              row.add(Tile.piece(PieceType.knight, Player.white));
            }
          case 'B':
            {
              row.add(Tile.piece(PieceType.bishop, Player.white));
            }
          case 'R':
            {
              row.add(Tile.piece(PieceType.rook, Player.white));
            }
          case 'Q':
            {
              row.add(Tile.piece(PieceType.queen, Player.white));
            }
          case 'K':
            {
              row.add(Tile.piece(PieceType.king, Player.white));
            }
        }
      }

      if (row.length != BOARD_FILES) {
        throw StateError('The FEN definition $rawRow is not correct');
      }

      tiles.addAll(row);
    }

    return tiles;
  }
}

class PGNParser implements Parser<Game> {
  static final _wsRE = r'[\n\r\t ]*';
  static final _headerRE = r'\[[a-zA-Z]+ ".+?"\]';
  static final _headersRE = r'(?<headers>(?:' + _headerRE + r'\n)+)';
  static final _moveRE = r'(?:O-O|O-O-O|[NBRQK]?[a-h]?[1-8]?x?[a-h][1-8](?:=[NBRQ])?[+#]?)';
  static final _metaRE = r'(?:\{\[%clk [0-9]+:[0-9]+:[0-9]+(?:\.[0-9]+)?\]\})?';
  static final _whiteMoveRE = r'[0-9]+\.' + _wsRE + _moveRE + _wsRE + _metaRE;
  static final _blackMoveRE = r'[0-9]+\.\.\.' + _wsRE + _moveRE + _wsRE + _metaRE;
  static final _allMovesRE =
      r'(?<moves>(?:' + _whiteMoveRE + _wsRE + r'(?:' + _blackMoveRE + _wsRE + r')?)+)';
  static final _scoreRE = r'(?<wscore>[01])-(?<bscore>[01])';
  static final _pgnRE = _headersRE + r'\n' + _allMovesRE + _scoreRE + r'\n';

  static final pgnRegExp = RegExp(_pgnRE);

  final _headerParser = HeaderParser();
  final _moveParser = MoveParser();

  /// Whether the provided PGN string [pgn] has a valid and supported format.
  bool validate(String pgn) {
    return pgnRegExp.hasMatch(pgn);
  }

  @override
  Game parse(String pgn) {
    final match = pgnRegExp.firstMatch(pgn);

    if (match == null) {
      throw ArgumentError('The provided string is not in a valid or supported PGN format');
    }

    final rawHeaders = match.namedGroup('headers');
    final rawMoves = match.namedGroup('moves');
    final rawWhiteScore = match.namedGroup('wscore');
    final rawBlackScore = match.namedGroup('bscore');

    if (rawHeaders == null) {
      throw StateError('No header found in the PGN string');
    }

    final headers = _headerParser.parse(rawHeaders);

    if (rawMoves == null) {
      throw StateError('No move found in the PGN string');
    }

    final moves = _moveParser.parse(rawMoves);

    if (rawWhiteScore == null || rawBlackScore == null) {
      throw StateError('No valid score found in the PGN string');
    }

    final whiteScore = int.parse(rawWhiteScore);
    final blackScore = int.parse(rawBlackScore);

    if ((whiteScore != 0 && whiteScore != 1) || (blackScore != 0 && blackScore != 1)) {
      throw StateError('The score must be 0 or 1');
    }

    return Game(headers: headers, moves: moves, whiteScore: whiteScore, blackScore: blackScore);
  }
}

class HeaderParser implements Parser<Map<String, String>> {
  static final _headerRE = r'\[(?<key>[a-zA-Z]+) "(?<value>.+?)"\]';

  static final headerRegExp = RegExp(_headerRE);

  @override
  Map<String, String> parse(String pgnHeaders) {
    final headers = <String, String>{};

    for (final match in headerRegExp.allMatches(pgnHeaders)) {
      final rawKey = match.namedGroup('key');
      final rawValue = match.namedGroup('value');

      if (rawKey == null || rawValue == null) {
        throw StateError('Malformed key-value pair');
      }

      headers[rawKey] = rawValue;
    }

    return headers;
  }
}

class MoveParser implements Parser<List<Move>> {
  static final _wsRE = r'[\n\r\t ]*';
  static final _moveRE =
      r'(?<move>O-O|O-O-O|(?<type>[NBRQK])?(?<file>[a-h])?(?<rank>[1-8])?(?<cap>x)?(?<to>[a-h][1-8])(?:=(?<prom>[NBRQ]))?(?<check>[+#])?)';
  static final _metaRE = r'(?:\{(?<meta>\[%clk [0-9]+:[0-9]+:[0-9]+(?:\.[0-9]+)?\])\})?';
  static final _whiteMoveRE = r'[0-9]+\.' + _wsRE + _moveRE + _wsRE + _metaRE;
  static final _blackMoveRE = r'[0-9]+\.\.\.' + _wsRE + _moveRE + _wsRE + _metaRE;

  static final whiteMoveRegExp = RegExp(_whiteMoveRE);
  static final blackMoveRegExp = RegExp(_blackMoveRE);

  @override
  List<Move> parse(String pgnMoves) {
    final whiteMoves = _parsePlayerMoves(Player.white, pgnMoves);
    final blackMoves = _parsePlayerMoves(Player.black, pgnMoves);

    final moves = <Move>[];

    for (var i = 0; i < whiteMoves.length; i++) {
      moves.add(whiteMoves[i]);

      if (i < blackMoves.length) {
        moves.add(blackMoves[i]);
      }
    }

    return moves;
  }

  List<Move> _parsePlayerMoves(Player player, String pgnMoves) {
    final re = player == Player.white ? whiteMoveRegExp : blackMoveRegExp;

    final moves = <Move>[];
    final movedPawns = <int>{};

    for (final match in re.allMatches(pgnMoves)) {
      final rawMove = match.namedGroup('move');
      final rawType = match.namedGroup('type');
      final rawFile = match.namedGroup('file');
      final rawRank = match.namedGroup('rank');
      final rawTo = match.namedGroup('to');

      final capture = match.namedGroup('cap') == 'x';
      final check = match.namedGroup('check') == '+';
      final checkmate = match.namedGroup('check') == '#';
      final meta = match.namedGroup('meta') ?? '';
      final promotion = switch (match.namedGroup('prom')) {
        'N' => PieceType.knight,
        'B' => PieceType.bishop,
        'R' => PieceType.rook,
        'Q' => PieceType.queen,
        _ => null,
      };

      if (rawMove == null) {
        throw StateError('There is no move to parse');
      }

      if (rawMove == 'O-O') {
        moves.add(
            KingKingCastling(player, null, null, check: check, checkmate: checkmate, meta: meta));
      } else if (rawMove == 'O-O-O') {
        moves.add(
            KingQueenCastling(player, null, null, check: check, checkmate: checkmate, meta: meta));
      } else {
        if (rawTo == null) {
          throw StateError('There is no destination to parse');
        }

        Coords to = Coords.pos(rawTo);

        Coords? from = rawFile != null
            ? Coords.file(rawFile)
            : (rawRank != null ? Coords.rank(rawRank) : null);

        switch (rawType) {
          case null:
            {
              if (capture) {
                if (from == null || !from.fileIsValid) {
                  throw StateError('There is a PawnCapture move without origin: $rawMove');
                }

                moves.add(PawnCapture(player, from, to,
                    check: check, checkmate: checkmate, meta: meta, promotion: promotion));

                movedPawns.add(from.file);
              } else {
                if ((player == Player.white && to.rank == 4) ||
                    (player == Player.black && to.rank == 5)) {
                  if (movedPawns.contains(to.file)) {
                    // the pawn has already been moved; this is a PawnSingleMove
                    moves.add(PawnSingleMove(player, from, to,
                        check: check, checkmate: checkmate, meta: meta));
                  } else {
                    // the pawn has *not* been moved yet; this is a PawnDoubleMove
                    moves.add(PawnDoubleMove(player, from, to,
                        check: check, checkmate: checkmate, meta: meta));
                  }
                } else {
                  // on any other rank, this is necessarily a PawnSingleMove
                  moves.add(PawnSingleMove(player, from, to,
                      check: check, checkmate: checkmate, meta: meta, promotion: promotion));
                }

                movedPawns.add(to.file);
              }
            }
          case 'N':
            {
              if (capture) {
                moves.add(KnightCapture(player, from, to,
                    check: check, checkmate: checkmate, meta: meta));
              } else {
                moves.add(
                    KnightMove(player, from, to, check: check, checkmate: checkmate, meta: meta));
              }
            }
          case 'B':
            {
              if (capture) {
                moves.add(BishopCapture(player, from, to,
                    check: check, checkmate: checkmate, meta: meta));
              } else {
                moves.add(
                    BishopMove(player, from, to, check: check, checkmate: checkmate, meta: meta));
              }
            }
          case 'R':
            {
              if (capture) {
                moves.add(
                    RookCapture(player, from, to, check: check, checkmate: checkmate, meta: meta));
              } else {
                moves.add(
                    RookMove(player, from, to, check: check, checkmate: checkmate, meta: meta));
              }
            }
          case 'Q':
            {
              if (capture) {
                moves.add(
                    QueenCapture(player, from, to, check: check, checkmate: checkmate, meta: meta));
              } else {
                moves.add(
                    QueenMove(player, from, to, check: check, checkmate: checkmate, meta: meta));
              }
            }
          case 'K':
            {
              if (capture) {
                moves.add(
                    KingCapture(player, from, to, check: check, checkmate: checkmate, meta: meta));
              } else {
                moves.add(
                    KingMove(player, from, to, check: check, checkmate: checkmate, meta: meta));
              }
            }
        }
      }
    }

    return moves;
  }
}
