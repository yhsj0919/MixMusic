String formatTime(Duration value) =>
    '${value.inMinutes}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';
