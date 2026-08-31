// コード管理番号: VER-20260831-02

/// 活用形の種類
enum InflectionType {
  base('原形・原級'),
  past('過去形'),
  pastParticiple('過去分詞'),
  thirdPersonSingular('三単現'),
  presentParticiple('-ing'),
  comparative('比較級'),
  superlative('最上級'),
  singular('単数形'),
  plural('複数形');

  final String label;
  const InflectionType(this.label);
}

/// 単一の活用形エントリ
class InflectionItem {
  final InflectionType type;
  final String word;
  final String label;

  const InflectionItem({
    required this.type,
    required this.word,
    required this.label,
  });
}

/// 単語の活用形ファミリー（原形・過去形・過去分詞・比較級・最上級・複数形等の一覧）
class InflectionFamily {
  final String baseForm;
  final String categoryName; // '形容詞・副詞 (比較変化)', '動詞 (活用変化)', '名詞 (複数形変化)'
  final List<InflectionItem> items;

  const InflectionFamily({
    required this.baseForm,
    required this.categoryName,
    required this.items,
  });
}

/// 不規則変化・活用体系管理サービス (F-01 / F-22)
class InflectionService {
  InflectionService._();
  static final InflectionService instance = InflectionService._();

  // --- 1. 形容詞・副詞 比較変化マスター ---
  static const List<({String base, String comp, String sup})> _comparisonMaster = [
    (base: 'good', comp: 'better', sup: 'best'),
    (base: 'well', comp: 'better', sup: 'best'),
    (base: 'bad', comp: 'worse', sup: 'worst'),
    (base: 'badly', comp: 'worse', sup: 'worst'),
    (base: 'ill', comp: 'worse', sup: 'worst'),
    (base: 'many', comp: 'more', sup: 'most'),
    (base: 'much', comp: 'more', sup: 'most'),
    (base: 'little', comp: 'less', sup: 'least'),
    (base: 'far', comp: 'farther / further', sup: 'farthest / furthest'),
    (base: 'old', comp: 'older / elder', sup: 'oldest / eldest'),
    (base: 'late', comp: 'later / latter', sup: 'latest / last'),
    (base: 'near', comp: 'nearer', sup: 'nearest / next'),
  ];

  // --- 2. 名詞 不規則複数形マスター ---
  static const List<({String singular, String plural})> _nounPluralMaster = [
    (singular: 'child', plural: 'children'),
    (singular: 'person', plural: 'people'),
    (singular: 'man', plural: 'men'),
    (singular: 'woman', plural: 'women'),
    (singular: 'tooth', plural: 'teeth'),
    (singular: 'foot', plural: 'feet'),
    (singular: 'goose', plural: 'geese'),
    (singular: 'mouse', plural: 'mice'),
    (singular: 'louse', plural: 'lice'),
    (singular: 'ox', plural: 'oxen'),
    (singular: 'criterion', plural: 'criteria'),
    (singular: 'datum', plural: 'data'),
    (singular: 'medium', plural: 'media'),
    (singular: 'phenomenon', plural: 'phenomena'),
    (singular: 'analysis', plural: 'analyses'),
    (singular: 'basis', plural: 'bases'),
    (singular: 'crisis', plural: 'crises'),
    (singular: 'hypothesis', plural: 'hypotheses'),
    (singular: 'parenthesis', plural: 'parentheses'),
    (singular: 'thesis', plural: 'theses'),
    (singular: 'cactus', plural: 'cacti'),
    (singular: 'fungus', plural: 'fungi'),
    (singular: 'nucleus', plural: 'nuclei'),
    (singular: 'syllabus', plural: 'syllabi'),
    (singular: 'sheep', plural: 'sheep'),
    (singular: 'deer', plural: 'deer'),
    (singular: 'fish', plural: 'fish'),
    (singular: 'species', plural: 'species'),
  ];

  // --- 3. 動詞 不規則活用マスター (原形, 過去形, 過去分詞, 三単現, 現在分詞) ---
  static const List<({String base, String past, String pp, String? third, String? ing})> _verbMaster = [
    (base: 'be', past: 'was / were', pp: 'been', third: 'is', ing: 'being'),
    (base: 'have', past: 'had', pp: 'had', third: 'has', ing: 'having'),
    (base: 'do', past: 'did', pp: 'done', third: 'does', ing: 'doing'),
    (base: 'go', past: 'went', pp: 'gone', third: 'goes', ing: 'going'),
    (base: 'make', past: 'made', pp: 'made', third: 'makes', ing: 'making'),
    (base: 'get', past: 'got', pp: 'got / gotten', third: 'gets', ing: 'getting'),
    (base: 'take', past: 'took', pp: 'taken', third: 'takes', ing: 'taking'),
    (base: 'see', past: 'saw', pp: 'seen', third: 'sees', ing: 'seeing'),
    (base: 'come', past: 'came', pp: 'come', third: 'comes', ing: 'coming'),
    (base: 'know', past: 'knew', pp: 'known', third: 'knows', ing: 'knowing'),
    (base: 'think', past: 'thought', pp: 'thought', third: 'thinks', ing: 'thinking'),
    (base: 'tell', past: 'told', pp: 'told', third: 'tells', ing: 'telling'),
    (base: 'say', past: 'said', pp: 'said', third: 'says', ing: 'saying'),
    (base: 'give', past: 'gave', pp: 'given', third: 'gives', ing: 'giving'),
    (base: 'find', past: 'found', pp: 'found', third: 'finds', ing: 'finding'),
    (base: 'leave', past: 'left', pp: 'left', third: 'leaves', ing: 'leaving'),
    (base: 'feel', past: 'felt', pp: 'felt', third: 'feels', ing: 'feeling'),
    (base: 'bring', past: 'brought', pp: 'brought', third: 'brings', ing: 'bringing'),
    (base: 'begin', past: 'began', pp: 'begun', third: 'begins', ing: 'beginning'),
    (base: 'keep', past: 'kept', pp: 'kept', third: 'keeps', ing: 'keeping'),
    (base: 'hold', past: 'held', pp: 'held', third: 'holds', ing: 'holding'),
    (base: 'write', past: 'wrote', pp: 'written', third: 'writes', ing: 'writing'),
    (base: 'stand', past: 'stood', pp: 'stood', third: 'stands', ing: 'standing'),
    (base: 'hear', past: 'heard', pp: 'heard', third: 'hears', ing: 'hearing'),
    (base: 'let', past: 'let', pp: 'let', third: 'lets', ing: 'letting'),
    (base: 'mean', past: 'meant', pp: 'meant', third: 'means', ing: 'meaning'),
    (base: 'set', past: 'set', pp: 'set', third: 'sets', ing: 'setting'),
    (base: 'meet', past: 'met', pp: 'met', third: 'meets', ing: 'meeting'),
    (base: 'run', past: 'ran', pp: 'run', third: 'runs', ing: 'running'),
    (base: 'pay', past: 'paid', pp: 'paid', third: 'pays', ing: 'paying'),
    (base: 'sit', past: 'sat', pp: 'sat', third: 'sits', ing: 'sitting'),
    (base: 'speak', past: 'spoke', pp: 'spoken', third: 'speaks', ing: 'speaking'),
    (base: 'lie', past: 'lay', pp: 'lain', third: 'lies', ing: 'lying'),
    (base: 'lead', past: 'led', pp: 'led', third: 'leads', ing: 'leading'),
    (base: 'read', past: 'read', pp: 'read', third: 'reads', ing: 'reading'),
    (base: 'grow', past: 'grew', pp: 'grown', third: 'grows', ing: 'growing'),
    (base: 'lose', past: 'lost', pp: 'lost', third: 'loses', ing: 'losing'),
    (base: 'fall', past: 'fell', pp: 'fallen', third: 'falls', ing: 'falling'),
    (base: 'send', past: 'sent', pp: 'sent', third: 'sends', ing: 'sending'),
    (base: 'build', past: 'built', pp: 'built', third: 'builds', ing: 'building'),
    (base: 'understand', past: 'understood', pp: 'understood', third: 'understands', ing: 'understanding'),
    (base: 'draw', past: 'drew', pp: 'drawn', third: 'draws', ing: 'drawing'),
    (base: 'break', past: 'broke', pp: 'broken', third: 'breaks', ing: 'breaking'),
    (base: 'spend', past: 'spent', pp: 'spent', third: 'spends', ing: 'spending'),
    (base: 'cut', past: 'cut', pp: 'cut', third: 'cuts', ing: 'cutting'),
    (base: 'rise', past: 'rose', pp: 'risen', third: 'rises', ing: 'rising'),
    (base: 'drive', past: 'drove', pp: 'driven', third: 'drives', ing: 'driving'),
    (base: 'buy', past: 'bought', pp: 'bought', third: 'buys', ing: 'buying'),
    (base: 'wear', past: 'wore', pp: 'worn', third: 'wears', ing: 'wearing'),
    (base: 'choose', past: 'chose', pp: 'chosen', third: 'chooses', ing: 'choosing'),
    (base: 'eat', past: 'ate', pp: 'eaten', third: 'eats', ing: 'eating'),
    (base: 'catch', past: 'caught', pp: 'caught', third: 'catches', ing: 'catching'),
    (base: 'win', past: 'won', pp: 'won', third: 'wins', ing: 'winning'),
    (base: 'fly', past: 'flew', pp: 'flown', third: 'flies', ing: 'flying'),
    (base: 'forget', past: 'forgot', pp: 'forgotten', third: 'forgets', ing: 'forgetting'),
    (base: 'teach', past: 'taught', pp: 'taught', third: 'teaches', ing: 'teaching'),
    (base: 'drink', past: 'drank', pp: 'drunk', third: 'drinks', ing: 'drinking'),
    (base: 'sing', past: 'sang', pp: 'sung', third: 'sings', ing: 'singing'),
    (base: 'sleep', past: 'slept', pp: 'slept', third: 'sleeps', ing: 'sleeping'),
    (base: 'swim', past: 'swam', pp: 'swum', third: 'swims', ing: 'swimming'),
    (base: 'throw', past: 'threw', pp: 'thrown', third: 'throws', ing: 'throwing'),
    (base: 'wake', past: 'woke', pp: 'woken', third: 'wakes', ing: 'waking'),
    (base: 'put', past: 'put', pp: 'put', third: 'puts', ing: 'putting'),
    (base: 'hit', past: 'hit', pp: 'hit', third: 'hits', ing: 'hitting'),
    (base: 'hurt', past: 'hurt', pp: 'hurt', third: 'hurts', ing: 'hurting'),
    (base: 'cost', past: 'cost', pp: 'cost', third: 'costs', ing: 'costing'),
    (base: 'shut', past: 'shut', pp: 'shut', third: 'shuts', ing: 'shutting'),
    (base: 'arise', past: 'arose', pp: 'arisen', third: 'arises', ing: 'arising'),
    (base: 'awake', past: 'awoke', pp: 'awoken', third: 'awakes', ing: 'awaking'),
    (base: 'bear', past: 'bore', pp: 'borne', third: 'bears', ing: 'bearing'),
    (base: 'beat', past: 'beat', pp: 'beaten', third: 'beats', ing: 'beating'),
    (base: 'become', past: 'became', pp: 'become', third: 'becomes', ing: 'becoming'),
    (base: 'bend', past: 'bent', pp: 'bent', third: 'bends', ing: 'bending'),
    (base: 'bet', past: 'bet', pp: 'bet', third: 'bets', ing: 'betting'),
    (base: 'bind', past: 'bound', pp: 'bound', third: 'binds', ing: 'binding'),
    (base: 'bite', past: 'bit', pp: 'bitten', third: 'bites', ing: 'biting'),
    (base: 'bleed', past: 'bled', pp: 'bled', third: 'bleeds', ing: 'bleeding'),
    (base: 'blow', past: 'blew', pp: 'blown', third: 'blows', ing: 'blowing'),
    (base: 'breed', past: 'bred', pp: 'bred', third: 'breeds', ing: 'breeding'),
    (base: 'burn', past: 'burnt / burned', pp: 'burnt / burned', third: 'burns', ing: 'burning'),
    (base: 'creep', past: 'crept', pp: 'crept', third: 'creeps', ing: 'creeping'),
    (base: 'deal', past: 'dealt', pp: 'dealt', third: 'deals', ing: 'dealing'),
    (base: 'dig', past: 'dug', pp: 'dug', third: 'digs', ing: 'digging'),
    (base: 'dream', past: 'dreamt / dreamed', pp: 'dreamt / dreamed', third: 'dreams', ing: 'dreaming'),
    (base: 'feed', past: 'fed', pp: 'fed', third: 'feeds', ing: 'feeding'),
    (base: 'fight', past: 'fought', pp: 'fought', third: 'fights', ing: 'fighting'),
    (base: 'flee', past: 'fled', pp: 'fled', third: 'flees', ing: 'fleeing'),
    (base: 'forbid', past: 'forbade', pp: 'forbidden', third: 'forbids', ing: 'forbidding'),
    (base: 'forgive', past: 'forgave', pp: 'forgiven', third: 'forgives', ing: 'forgiving'),
    (base: 'freeze', past: 'froze', pp: 'frozen', third: 'freezes', ing: 'freezing'),
    (base: 'hang', past: 'hung', pp: 'hung', third: 'hangs', ing: 'hanging'),
    (base: 'hide', past: 'hid', pp: 'hidden', third: 'hides', ing: 'hiding'),
    (base: 'kneel', past: 'knelt', pp: 'knelt', third: 'kneels', ing: 'kneeling'),
    (base: 'lay', past: 'laid', pp: 'laid', third: 'lays', ing: 'laying'),
    (base: 'lean', past: 'leant / leaned', pp: 'leant / leaned', third: 'leans', ing: 'leaning'),
    (base: 'leap', past: 'leapt / leaped', pp: 'leapt / leaped', third: 'leaps', ing: 'leaping'),
    (base: 'learn', past: 'learnt / learned', pp: 'learnt / learned', third: 'learns', ing: 'learning'),
    (base: 'lend', past: 'lent', pp: 'lent', third: 'lends', ing: 'lending'),
    (base: 'light', past: 'lit / lighted', pp: 'lit / lighted', third: 'lights', ing: 'lighting'),
    (base: 'ride', past: 'rode', pp: 'ridden', third: 'rides', ing: 'riding'),
    (base: 'ring', past: 'rang', pp: 'rung', third: 'rings', ing: 'ringing'),
    (base: 'seek', past: 'sought', pp: 'sought', third: 'seeks', ing: 'seeking'),
    (base: 'sell', past: 'sold', pp: 'sold', third: 'sells', ing: 'selling'),
    (base: 'sew', past: 'sewed', pp: 'sewn / sewed', third: 'sews', ing: 'sewing'),
    (base: 'shake', past: 'shook', pp: 'shaken', third: 'shakes', ing: 'shaking'),
    (base: 'shine', past: 'shone', pp: 'shone', third: 'shines', ing: 'shining'),
    (base: 'shoot', past: 'shot', pp: 'shot', third: 'shoots', ing: 'shooting'),
    (base: 'show', past: 'showed', pp: 'shown / showed', third: 'shows', ing: 'showing'),
    (base: 'sink', past: 'sank', pp: 'sunk', third: 'sinks', ing: 'sinking'),
    (base: 'slide', past: 'slid', pp: 'slid', third: 'slides', ing: 'sliding'),
    (base: 'spin', past: 'spun', pp: 'spun', third: 'spins', ing: 'spinning'),
    (base: 'spit', past: 'spit / spat', pp: 'spit / spat', third: 'spits', ing: 'spitting'),
    (base: 'split', past: 'split', pp: 'split', third: 'splits', ing: 'splitting'),
    (base: 'spread', past: 'spread', pp: 'spread', third: 'spreads', ing: 'spreading'),
    (base: 'spring', past: 'sprang', pp: 'sprung', third: 'springs', ing: 'springing'),
    (base: 'steal', past: 'stole', pp: 'stolen', third: 'steals', ing: 'stealing'),
    (base: 'stick', past: 'stuck', pp: 'stuck', third: 'sticks', ing: 'sticking'),
    (base: 'sting', past: 'stung', pp: 'stung', third: 'stings', ing: 'stinging'),
    (base: 'strike', past: 'struck', pp: 'struck', third: 'strikes', ing: 'striking'),
    (base: 'swear', past: 'swore', pp: 'sworn', third: 'swears', ing: 'swearing'),
    (base: 'sweep', past: 'swept', pp: 'swept', third: 'sweeps', ing: 'sweeping'),
    (base: 'swing', past: 'swung', pp: 'swung', third: 'swings', ing: 'swinging'),
    (base: 'tear', past: 'tore', pp: 'torn', third: 'tears', ing: 'tearing'),
    (base: 'wind', past: 'wound', pp: 'wound', third: 'winds', ing: 'winding'),
  ];

  /// 単語（原形または活用形）から、該当する活用形ファミリーを取得する
  InflectionFamily? getInflectionFamily(String word, {String? baseForm}) {
    final cleanWord = word.toLowerCase().trim();
    final cleanBase = baseForm?.toLowerCase().trim();

    // 1. 比較変化 (形容詞・副詞) の検索 (例: good, better, best)
    for (final row in _comparisonMaster) {
      if (cleanWord == row.base ||
          cleanBase == row.base ||
          _matchesField(cleanWord, row.comp) ||
          _matchesField(cleanWord, row.sup)) {
        return InflectionFamily(
          baseForm: row.base,
          categoryName: '比較変化 (比較級・最上級)',
          items: [
            InflectionItem(type: InflectionType.base, word: row.base, label: '原級'),
            InflectionItem(type: InflectionType.comparative, word: row.comp, label: '比較級'),
            InflectionItem(type: InflectionType.superlative, word: row.sup, label: '最上級'),
          ],
        );
      }
    }

    // 2. 名詞 (不規則複数形) の検索 (例: child, children / tooth, teeth)
    for (final row in _nounPluralMaster) {
      if (cleanWord == row.singular ||
          cleanBase == row.singular ||
          cleanWord == row.plural) {
        return InflectionFamily(
          baseForm: row.singular,
          categoryName: '名詞変化 (単数・複数)',
          items: [
            InflectionItem(type: InflectionType.singular, word: row.singular, label: '単数形'),
            InflectionItem(type: InflectionType.plural, word: row.plural, label: '複数形'),
          ],
        );
      }
    }

    // 3. 動詞 (不規則活用) の検索 (例: go, went, gone / make, made, made)
    for (final row in _verbMaster) {
      if (cleanWord == row.base ||
          cleanBase == row.base ||
          _matchesField(cleanWord, row.past) ||
          _matchesField(cleanWord, row.pp) ||
          (row.third != null && cleanWord == row.third) ||
          (row.ing != null && cleanWord == row.ing)) {
        final list = <InflectionItem>[
          InflectionItem(type: InflectionType.base, word: row.base, label: '原形'),
          InflectionItem(type: InflectionType.past, word: row.past, label: '過去形'),
          InflectionItem(type: InflectionType.pastParticiple, word: row.pp, label: '過去分詞'),
        ];
        if (row.third != null) {
          list.add(InflectionItem(type: InflectionType.thirdPersonSingular, word: row.third!, label: '三単現'));
        }
        if (row.ing != null) {
          list.add(InflectionItem(type: InflectionType.presentParticiple, word: row.ing!, label: '-ing'));
        }
        return InflectionFamily(
          baseForm: row.base,
          categoryName: '動詞活用 (不規則変化)',
          items: list,
        );
      }
    }

    return null;
  }

  static bool _matchesField(String target, String field) {
    if (field.contains('/')) {
      final parts = field.split('/').map((s) => s.trim().toLowerCase());
      return parts.contains(target);
    }
    return target == field.trim().toLowerCase();
  }
}
