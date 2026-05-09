class CardSet {
  final String id;
  final String name;
  final String? releaseDate;

  const CardSet({
    required this.id,
    required this.name,
    this.releaseDate,
  });

  factory CardSet.fromJson(Map<String, dynamic> json) {
    return CardSet(
      id: json['id'] as String,
      name: json['name'] as String,
      releaseDate: json['release_date'] as String?,
    );
  }
}