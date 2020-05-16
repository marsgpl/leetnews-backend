class Perf {
    static DateTime startTime;

    static void start() {
        startTime = DateTime.now();
    }

    static void end(String message) {
        if (startTime == null) {
            throw Exception('Perf.end() called before Perf.start()');
        }

        final endTime = DateTime.now();
        final diff = endTime.difference(startTime).inMilliseconds;

        print('$message: ${diff}ms');
    }
}
