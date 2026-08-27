class SubscriptionModel {
  final String id;
  final String title;
  final double price;
  final String duration;
  final String subtitle;
  final List<String> features;

  SubscriptionModel({
    required this.id,
    required this.title,
    required this.price,
    required this.duration,
    required this.subtitle,
    required this.features,
  });
}
