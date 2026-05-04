/// Set IDs corresponding to main FaB expansions plus "History Pack 1."
/// Other set IDs (armory decks, blitz decks, promos, etc.) are excluded
/// from the filter UI because they contain reprints, not unique cards
/// players would typically filter by.
///
/// Update this list when new main expansions release. Last updated for
/// version v8.1.0 of the-fab-cube/flesh-and-blood-cards.
const Set<String> kMainSetIds = {
  '1HP', // History Pack 1
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
};