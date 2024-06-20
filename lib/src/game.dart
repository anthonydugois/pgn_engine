import 'moves.dart';
import 'parsers.dart';

class Game {
  final Map<String, String> headers;
  final List<Move> moves;
  final int whiteScore;
  final int blackScore;

  Game(
      {required this.headers,
      required this.moves,
      required this.whiteScore,
      required this.blackScore});

  factory Game.fromPGN(String pgn) {
    final parser = PGNParser();

    if (!parser.validate(pgn)) {
      throw ArgumentError('Invalid or unsupported PGN format');
    }

    return parser.parse(pgn);
  }
}
