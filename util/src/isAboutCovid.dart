const CHUNKS = [
    'карона',
    'корона',
    'вирус',
    'карантин',
    'эпидеми',
    'пандеми',
    'заразил',
    'заражен',
    'заражён',
    'ковид',
    'covid',
    'corona',
    'virus',
];

const WORDS = [
    'воз',
];

final wordSplitter = RegExp(r'[^а-яА-Яa-zA-Z0-9ёЁ\-]+');

bool isAboutCovid(String text) {
    text = text.toLowerCase();

    for (int i = 0; i < CHUNKS.length; ++i) {
        final chunk = CHUNKS[i];
        if (text.contains(chunk)) return true;
    }

    final parts = text.split(wordSplitter);

    for (int i = 0; i < parts.length; ++i) {
        final part = parts[i];
        for (int i2 = 0; i2 < WORDS.length; ++i2) {
            final word = WORDS[i2];
            if (part == word) return true;
        }
    }

    return false;
}
