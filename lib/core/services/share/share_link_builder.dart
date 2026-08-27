class ShareLinkBuilder {
  const ShareLinkBuilder._();

  static const String baseHost = 'vendza.app';

  static String productUrl(String id) => 'https://$baseHost/p/$id';

  static String storeUrl(String id) => 'https://$baseHost/store/$id';
}
