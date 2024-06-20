import 'package:pgn_engine/pgn_engine.dart';

void main() {
  var pgn =
      '[Event "Live Chess"]\n[Site "Chess.com"]\n[Date "2024.06.01"]\n[Round "-"]\n[White "erik"]\n[Black "RafalButny"]\n[Result "1-0"]\n[CurrentPosition "r4r2/6RR/1p6/p2pNq1p/3Pp2k/6Pp/PP2QP2/6K1 b - -"]\n[Timezone "UTC"]\n[ECO "B13"]\n[ECOUrl "https://www.chess.com/openings/Caro-Kann-Defense-Exchange-Variation...4.Bd3-Nf6-5.h3-Nc6"]\n[UTCDate "2024.06.01"]\n[UTCTime "14:14:39"]\n[WhiteElo "1628"]\n[BlackElo "1603"]\n[TimeControl "60+1"]\n[Termination "erik won by checkmate"]\n[StartTime "14:14:39"]\n[EndDate "2024.06.01"]\n[EndTime "14:17:13"]\n[Link "https://www.chess.com/game/live/110990419821"]\n\n1. e4 {[%clk 0:01:01]} 1... c6 {[%clk 0:01:01]} 2. d4 {[%clk 0:01:01.3]} 2... d5 {[%clk 0:01:01.3]} 3. exd5 {[%clk 0:01:02.2]} 3... cxd5 {[%clk 0:01:02]} 4. Bd3 {[%clk 0:01:02.9]} 4... Nf6 {[%clk 0:01:02.5]} 5. h3 {[%clk 0:01:03.2]} 5... Nc6 {[%clk 0:01:02.2]} 6. c3 {[%clk 0:01:03.5]} 6... e6 {[%clk 0:01:01.5]} 7. Bf4 {[%clk 0:01:03.3]} 7... Bd6 {[%clk 0:01:01.3]} 8. Bxd6 {[%clk 0:01:03.3]} 8... Qxd6 {[%clk 0:01:01.6]} 9. Nf3 {[%clk 0:01:04.2]} 9... O-O {[%clk 0:01:01.8]} 10. O-O {[%clk 0:01:04.4]} 10... b6 {[%clk 0:01:02]} 11. Re1 {[%clk 0:01:04.8]} 11... a5 {[%clk 0:01:02.3]} 12. Qe2 {[%clk 0:01:05.1]} 12... Bb7 {[%clk 0:00:58.4]} 13. Ne5 {[%clk 0:01:04.9]} 13... Nd7 {[%clk 0:00:53.5]} 14. Nd2 {[%clk 0:01:01]} 14... Rfe8 {[%clk 0:00:50.9]} 15. Qh5 {[%clk 0:00:54.4]} 15... g6 {[%clk 0:00:48.7]} 16. Qe2 {[%clk 0:00:40.6]} 16... Kg7 {[%clk 0:00:44.1]} 17. Ndf3 {[%clk 0:00:40.1]} 17... f6 {[%clk 0:00:44.1]} 18. Ng4 {[%clk 0:00:39.7]} 18... e5 {[%clk 0:00:39.5]} 19. dxe5 {[%clk 0:00:39.7]} 19... fxe5 {[%clk 0:00:39.8]} 20. Bb5 {[%clk 0:00:35.4]} 20... e4 {[%clk 0:00:39]} 21. Nd4 {[%clk 0:00:30.5]} 21... Nxd4 {[%clk 0:00:37.1]} 22. cxd4 {[%clk 0:00:31.4]} 22... Rf8 {[%clk 0:00:33.8]} 23. Bxd7 {[%clk 0:00:28.8]} 23... Qxd7 {[%clk 0:00:33.7]} 24. Ne5 {[%clk 0:00:29.2]} 24... Qf5 {[%clk 0:00:33.9]} 25. Rac1 {[%clk 0:00:26.4]} 25... h5 {[%clk 0:00:31.5]} 26. Rc7+ {[%clk 0:00:26]} 26... Kh6 {[%clk 0:00:30.2]} 27. Rxb7 {[%clk 0:00:25.7]} 27... g5 {[%clk 0:00:30.6]} 28. Rc1 {[%clk 0:00:17.9]} 28... g4 {[%clk 0:00:30.3]} 29. Rcc7 {[%clk 0:00:17.4]} 29... gxh3 {[%clk 0:00:30.4]} 30. Rh7+ {[%clk 0:00:16.6]} 30... Kg5 {[%clk 0:00:30.7]} 31. Rbg7+ {[%clk 0:00:16]} 31... Kh4 {[%clk 0:00:29.8]} 32. g3# {[%clk 0:00:15.4]} 1-0\n';

  final game = Game.fromPGN(pgn);
  final executor = Executor(game);

  print(executor.board.FEN);
  print(executor.board);

  for (var i = 0; i < game.moves.length; i++) {
    executor.next();
    print(executor.board.FEN);
    print(executor.board);
  }
}

class Executor {
  final Game game;

  final List<Board> history = [Board.initial];

  int current = 0;

  Executor(this.game);

  Move? get prevMove => current <= 0 ? null : game.moves[current - 1];

  Move? get nextMove => game.moves[current];

  Board get board => history[current];

  void prev() {
    if (current > 0) {
      current -= 1;
    }
  }

  void next() {
    if (current >= history.length - 1) {
      final move = game.moves[current];
      final currentBoard = history[history.length - 1];
      final nextBoard = move.execute(currentBoard);

      history.add(nextBoard);
    }

    current += 1;
  }

  void start() {
    current = 0;
  }

  void end() {
    current = history.length - 1;
  }
}
