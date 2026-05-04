/// Set IDs corresponding to FaB core/expansion sets that exist in v8.1.0 of
/// the upstream data. Other set IDs (armory decks, hero decks, blitz decks,
/// promos, etc.) are excluded from the filter UI.
///
/// Sets released after v8.1.0 (Compendium of Rathe / PEN, Omens of the Third
/// Age) are not included here — they will become available when we bump the
/// upstream data version pin in tool/fetch_cards.dart.
const Set<String> kMainSetIds = {
  'WTR', // Welcome to Rathe
  'ARC', // Arcane Rising
  'CRU', // Crucible of War
  'MON', // Monarch
  'ELE', // Tales of Aria
  'EVR', // Everfest
  'UPR', // Uprising
  'OUT', // Outsiders
  'DTD', // Dusk till Dawn
  'DYN', // Dynasty
  'EVO', // Bright Lights
  'HVY', // Heavy Hitters
  'MST', // Part the Mistveil
  'ROS', // Rosetta
  'HNT', // The Hunted
  'SEA', // High Seas
  'SUP', // Super Slam
};