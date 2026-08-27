class ApiEndpoints {
  const ApiEndpoints._();

  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authGoogle = '/auth/google';
  static const authForgotPassword = '/auth/forgot-password';
  static const authResetPassword = '/auth/reset-password';
  static const authRefresh = '/auth/refresh';
  static const authLogout = '/auth/logout';
  static const authMe = '/auth/me';
  static const authBecomeSeller = '/auth/become-seller';
  static const authDeleteAccount = '/auth/delete-account';

  static const profileFullName = '/profil/fullname';
  static const profilePhone = '/profil/phone';
  static const profileAvatar = '/profil/avatar';
  static const profileAddress = '/profil/address';

  static const storeAdd = '/store/add';
  static const storeMy = '/store/my';
  static const storeBrowse = '/store/browse';
  static const homeFeed = '/home/feed';
  static const eventsProduct = '/events/product';

  static String storeUpdate(int storeId) => '/store/update/$storeId';
  static String storeName(int storeId) => '/store/name/$storeId';
  static String storeAddress(int storeId) => '/store/address/$storeId';
  static String storeDelete(int storeId) => '/store/delete/$storeId';

  static String productAdd(int storeId) => '/product/add/$storeId';
  static String productAllForStore(int storeId) => '/product/all/$storeId';
  static String productDetail(int productId) => '/product/$productId';

  static String productUpdate(int storeId, int productId) {
    return '/product/update/$storeId/$productId';
  }

  static String productDelete(int storeId, int productId) {
    return '/product/delete/$storeId/$productId';
  }

  static const productSearch = '/product/search';

  static const categories = '/categories';

  static String categoryProducts(int collectionId) {
    return '/categories/$collectionId/products';
  }

  static String categoryDelete(int collectionId) => '/categories/$collectionId';

  static String storeCollections(int storeId) {
    return '/store-collections/store/$storeId';
  }

  static String storeCollectionProducts(int collectionId) {
    return '/store-collections/$collectionId/products';
  }

  static String storeCollectionDelete(int collectionId) {
    return '/store-collections/$collectionId';
  }

  static const favorites = '/favorites';

  static String favoriteAdd(int productId) => '/favorites/$productId';

  static String favoriteRemove(int productId) => '/favorites/$productId';

  static const favoriteStores = '/favorites/stores';

  static String favoriteStore(int storeId) => '/favorites/stores/$storeId';

  static const uploadImagePresign = '/uploads/images/presign';

  static const notificationAdd = '/notification/add';

  /// Authenticated inbox for the current user (API: GET /notification/me).
  static const notificationsMe = '/notification/me';

  static const orders = '/orders';

  static String orderDetail(int orderId) => '/orders/$orderId';

  static String orderCancel(int orderId) => '/orders/$orderId/cancel';

  static String storeOrders(int storeId) => '/orders/store/$storeId';

  static String storeOrderStatus(int storeId, int orderId) {
    return '/orders/store/$storeId/$orderId/status';
  }

  static String notificationSeen(int notificationId) {
    return '/notification/seen/$notificationId';
  }

  static String notificationDelete(int notificationId) {
    return '/notification/delete/$notificationId';
  }
}
