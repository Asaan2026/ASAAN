import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vortex_app/core/config/api_config.dart';
import 'package:vortex_app/core/constants/app_colors.dart';
import 'package:vortex_app/data/models/product_model.dart';
import 'package:vortex_app/data/services/cart_service.dart';
import 'package:vortex_app/data/services/product_service.dart';
import 'package:vortex_app/data/services/wishlist_service.dart';
import 'package:vortex_app/l10n/app_localizations.dart';
import 'package:vortex_app/presentation/widgets/html_text.dart';
import 'package:vortex_app/presentation/widgets/price_text.dart';
import 'package:vortex_app/presentation/widgets/shopping_guard.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final WishlistService _wishlistService = WishlistService();

  int _currentPage = 0;
  int _quantity = 1;

  /// Whether this product is on the customer's saved list, and the id of the
  /// saved row so it can be taken off again. Both are read from the server on
  /// open: a filled heart that the server does not know about would take the
  /// product off the list on the next tap.
  bool _isFavorite = false;
  int? _favoriteItemId;

  bool _addingToCart = false;
  bool _savingFavorite = false;

  /// What the screen draws. It starts as whatever the previous screen handed
  /// over so the page paints straight away, then the full record from the
  /// server is merged in: product listings return a trimmed product, without
  /// the brand, weight, dimensions or the owner's own attributes.
  late Map<String, dynamic> _product;

  List<ProductModel> _related = [];
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _product = Map<String, dynamic>.of(widget.product);
    _loadFullProduct();
  }

  /// Nothing here is allowed to fail loudly: the screen already has enough to
  /// show the product, so a dropped connection just means the extra sections
  /// stay hidden rather than an error taking over the page.
  Future<void> _loadFullProduct() async {
    final id = (_product['id'] as num?)?.toInt();
    if (id == null || id == 0) return;

    try {
      final full = await _productService.getProduct(id);
      if (!mounted) return;
      setState(() => _product = {..._product, ...full});
    } catch (_) {
      // Keep what the previous screen gave us.
    }

    try {
      final related = await _productService.getRelatedProducts(id);
      if (!mounted) return;
      setState(() => _related = related);
    } catch (_) {
      // Section stays hidden.
    }

    try {
      final reviews = await _productService.getProductReviews(id);
      if (!mounted) return;
      setState(() => _reviews = reviews);
    } catch (_) {
      // Section falls back to the summary figures.
    }

    await _loadFavoriteState(id);
  }

  /// Is this product already on the saved list? Only worth asking when
  /// somebody is signed in; for everyone else the heart simply starts empty.
  Future<void> _loadFavoriteState(int productId) async {
    if (!await ShoppingGuard.isSignedIn()) return;

    try {
      final wishlist = await _wishlistService.getWishlist();
      final saved = wishlist.items
          .where((item) => item.product.id == productId)
          .toList();

      if (!mounted) return;
      setState(() {
        _isFavorite = saved.isNotEmpty;
        _favoriteItemId = saved.isEmpty ? null : saved.first.id;
      });
    } catch (_) {
      // Leave the heart empty rather than guessing.
    }
  }

  /// Put this product in the basket.
  ///
  /// The button used to do nothing at all: its onPressed was empty, so the
  /// shop could be browsed in the app but nothing could be bought.
  Future<void> _addToCart() async {
    if (_addingToCart) return;

    final l10n = AppLocalizations.of(context);
    final name = _product['name']?.toString() ?? '';

    setState(() => _addingToCart = true);

    final added = await ShoppingGuard.run(
      context,
      reason: l10n.guardReasonAddToBasket,
      action: () => _cartService.addToCart(
        productId: (_product['id'] as num?)?.toInt() ?? 0,
        quantity: _quantity,
      ),
    );

    if (!mounted) return;
    setState(() => _addingToCart = false);

    if (!added) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.productAddedToCart(name)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  /// Save the product for later, or take it off the list again.
  Future<void> _toggleFavorite() async {
    if (_savingFavorite) return;

    final l10n = AppLocalizations.of(context);
    final productId = (_product['id'] as num?)?.toInt() ?? 0;
    final wasFavorite = _isFavorite;
    final itemId = _favoriteItemId;

    setState(() => _savingFavorite = true);

    final done = await ShoppingGuard.run(
      context,
      reason: l10n.guardReasonSaveItem,
      action: () async {
        if (wasFavorite && itemId != null) {
          await _wishlistService.removeFromWishlist(itemId);
        } else {
          await _wishlistService.addToWishlist(productId);
        }
      },
    );

    if (!mounted) return;
    setState(() => _savingFavorite = false);

    if (!done) return;

    // Read the list back so the heart and the stored row cannot disagree.
    await _loadFavoriteState(productId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
      body: Stack(
        children: [
          // Main Content
          CustomScrollView(
            slivers: [
              // Image Carousel
              SliverToBoxAdapter(
                child: _buildImageCarousel(isDark),
              ),
              // Content
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(isDark),
                              const SizedBox(height: 12),
                              _buildShortDescription(isDark),
                              const SizedBox(height: 20),
                              _buildQuantityAndActions(isDark),
                              const SizedBox(height: 20),
                              _buildAddToCartButton(isDark),
                              const SizedBox(height: 16),
                              Divider(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, height: 1),
                              const SizedBox(height: 16),
                              _buildExpandableSections(isDark),
                              const SizedBox(height: 24),
                              _buildReviewsSection(isDark),
                              const SizedBox(height: 24),
                              _buildRelatedProducts(isDark),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Top App Bar
          _buildTopAppBar(isDark),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(bool isDark) {
    final productImages = _product['images'] as List<dynamic>?;
    final List<String> images = [];

    for (final img in productImages ?? const []) {
      if (img is String) {
        if (img.trim().isNotEmpty) images.add(img);
      } else if (img is Map) {
        final url = img['url']?.toString() ??
            img['path']?.toString() ??
            img['image']?.toString() ??
            '';
        if (url.trim().isNotEmpty) images.add(url);
      }
    }

    // A product with no pictures shows an icon drawn by the app. It used to
    // fetch a placeholder image from an outside website, which meant an empty
    // grey box whenever that site was unreachable.
    if (images.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Container(
          color: isDark ? const Color(0xFF182430) : Colors.white,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                color: isDark ? const Color(0xFF182430) : Colors.white,
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.image, size: 50));
                  },
                ),
              );
            },
          ),
          // Page Indicators
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final productName = _product['name']?.toString() ?? 'Product Name';
    final price = (_product['price'] ?? _product['discountPrice'] ?? 0.0) as num;
    final originalPrice = _product['discountPrice'] != null 
        ? (_product['price'] ?? 0.0) as num
        : null;
    final rating = (_product['rating'] ?? 0.0) as num;
    final reviewsCount = (_product['reviewsCount'] ?? _product['reviews_count'] ?? 0) as num;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            StyledPriceText(
              amount: price.toDouble(),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            if (originalPrice != null && originalPrice > price) ...[
              const SizedBox(width: 12),
              StyledPriceText(
                amount: originalPrice.toDouble(),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
                decoration: TextDecoration.lineThrough,
              ),
            ],
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.shade900.withOpacity(0.2) : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($reviewsCount reviews)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: (_product['stock'] as num? ?? 0) > 0 ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              (_product['stock'] as num? ?? 0) > 0 ? 'In Stock' : 'Out of Stock',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: (_product['stock'] as num? ?? 0) > 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '•',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(width: 16),
            Text(
              'SKU: ${_product['id']?.toString() ?? 'N/A'}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// The blurb under the product name. The dashboard calls this the short
  /// description; it is written in a rich-text editor, so it arrives as HTML
  /// and has to be rendered, not printed.
  Widget _buildShortDescription(bool isDark) {
    final short = _product['short_description']?.toString() ?? '';
    final full = _product['description']?.toString() ?? '';
    final text = short.trim().isNotEmpty ? short : full;

    if (text.trim().isEmpty) return const SizedBox.shrink();

    return HtmlText(
      html: text,
      baseStyle: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
        height: 1.5,
      ),
      linkColor: isDark ? Colors.lightBlue.shade200 : Colors.blue.shade700,
    );
  }

  /// The full description, as typed in the dashboard.
  Widget? _buildFullDescription(bool isDark) {
    final text = _product['description']?.toString() ?? '';
    if (text.trim().isEmpty) return null;

    return HtmlText(
      html: text,
      baseStyle: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
        height: 1.5,
      ),
      linkColor: isDark ? Colors.lightBlue.shade200 : Colors.blue.shade700,
    );
  }

  Widget _buildQuantityAndActions(bool isDark) {
    return Row(
      children: [
        // Quantity Selector
        Container(
          height: 48,
          width: 128,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF1C2630) : Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: IconButton(
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() => _quantity--);
                    }
                  },
                  icon: Icon(
                    Icons.remove,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              Text(
                '$_quantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () {
                    setState(() => _quantity++);
                  },
                  icon: Icon(
                    Icons.add,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Favorite Button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF1C2630) : Colors.white,
          ),
          child: IconButton(
            onPressed: _savingFavorite ? null : _toggleFavorite,
            icon: _savingFavorite
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey.shade500,
                    size: 20,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Share Button
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF1C2630) : Colors.white,
          ),
          child: IconButton(
            onPressed: _shareProduct,
            icon: Icon(
              Icons.share,
              color: Colors.grey.shade500,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// Hand the product's web address to the customer so they can send it to
  /// somebody. The button did nothing at all before.
  Future<void> _shareProduct() async {
    final slug = _product['slug']?.toString() ?? '';
    final id = (_product['id'] as num?)?.toInt();

    // The storefront page for this product, which anybody can open whether or
    // not they have the app.
    final link = slug.isNotEmpty
        ? '${ApiConfig.productionBaseUrl}/products/$slug'
        : (id == null ? '' : '${ApiConfig.productionBaseUrl}/products/$id');

    if (link.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).productLinkCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAddToCartButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _addingToCart ? null : _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_addingToCart)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(Icons.shopping_bag, size: 24),
            const SizedBox(width: 8),
            Text(
              _addingToCart
                  ? AppLocalizations.of(context).productAddingToCart
                  : AppLocalizations.of(context).productAddToCart,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSections(bool isDark) {
    final fullDescription = _buildFullDescription(isDark);
    final specifications = _buildSpecifications(isDark);

    final cards = <Widget>[
      if (fullDescription != null)
        _buildExpandableCard(AppLocalizations.of(context).productFullDescription, fullDescription, isDark),
      if (specifications != null)
        _buildExpandableCard(AppLocalizations.of(context).productSpecifications, specifications, isDark),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          cards[i],
        ],
      ],
    );
  }

  /// The product's own measurements and attributes, as entered in the
  /// dashboard. Only facts the shop actually recorded are listed, and the card
  /// is left out altogether when there are none — an empty "Specifications"
  /// heading tells a shopper nothing.
  Widget? _buildSpecifications(bool isDark) {
    final rows = <({String label, String value})>[];

    void add(String label, String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return;
      rows.add((label: label, value: text));
    }

    add(AppLocalizations.of(context).productSku, _product['sku']?.toString());

    final brand = _product['brand'];
    if (brand is Map) {
      add(AppLocalizations.of(context).productBrand, brand['name']?.toString());
    } else if (brand is String) {
      add(AppLocalizations.of(context).productBrand, brand);
    }

    add(AppLocalizations.of(context).productWeight, formatMeasure(_product['weight']));
    add(AppLocalizations.of(context).productDimensions, formatDimensions(_product['dimensions']));

    // Whatever the shop owner called them: colour, material, warranty.
    final attributes = _product['attributes'];
    if (attributes is List) {
      for (final attribute in attributes) {
        if (attribute is! Map) continue;
        final name = attribute['name']?.toString() ?? '';
        final value = attribute['value']?.toString() ?? '';
        if (name.isEmpty || value.trim().isEmpty) continue;
        add(name, value);
      }
    }

    if (rows.isEmpty) return null;

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          _buildSpecRow(
            rows[i].label,
            rows[i].value,
            isDark,
            isLast: i == rows.length - 1,
          ),
      ],
    );
  }

  Widget _buildExpandableCard(String title, Widget content, bool isDark) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2630) : Colors.white,
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          iconColor: Colors.grey.shade400,
          collapsedIconColor: Colors.grey.shade400,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  ),
                ),
              ),
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDark, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  style: BorderStyle.solid,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  /// Real ratings and real reviews, or an honest "none yet".
  ///
  /// There is no per-star breakdown in the API, so there are no distribution
  /// bars here: a bar chart that is not driven by the data is worse than no
  /// bar chart at all.
  Widget _buildReviewsSection(bool isDark) {
    final summary = _product['reviews_summary'];
    final rating = (_product['rating'] ??
        (summary is Map ? summary['average_rating'] : null) ??
        0.0) as num;
    final count = (_product['reviewsCount'] ??
        _product['reviews_count'] ??
        (summary is Map ? summary['total_reviews'] : null) ??
        0) as num;

    if (count <= 0 && _reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).productNoReviews,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count > 0 ? 'Reviews ($count)' : 'Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2630) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
              const SizedBox(width: 12),
              _buildStars(rating.toDouble(), 18),
              const Spacer(),
              Text(
                count == 1
                    ? AppLocalizations.of(context).productOneRating
                    : AppLocalizations.of(context).productRatingsCount(count.toInt()),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        for (final review in _reviews) ...[
          const SizedBox(height: 12),
          _buildReviewCard(review, isDark),
        ],
      ],
    );
  }

  Widget _buildStars(double rating, double size) {
    return Row(
      children: List.generate(5, (index) {
        final position = index + 1;
        final IconData icon;
        if (rating >= position) {
          icon = Icons.star;
        } else if (rating >= position - 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, color: Colors.amber, size: size);
      }),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isDark) {
    final customer = review['customer'];
    final name =
        customer is Map ? (customer['name']?.toString().trim() ?? '') : '';
    final displayName = name.isNotEmpty ? name : AppLocalizations.of(context).productVerifiedBuyer;
    final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
    final title = review['title']?.toString().trim() ?? '';
    final comment = review['comment']?.toString().trim() ?? '';
    final date = _formatReviewDate(review['created_at']?.toString());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2630) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initialsOfName(displayName),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
              ),
              if (date != null)
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStars(rating, 14),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _formatReviewDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateFormat.yMMMd().format(parsed.toLocal());
  }

  /// Other products from the same categories, as the server picks them.
  /// Hidden entirely when there are none, rather than filled with examples.
  Widget _buildRelatedProducts(bool isDark) {
    if (_related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).productRelatedProducts,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _related.length,
            itemBuilder: (context, index) {
              final product = _related[index];
              final imageUrl = firstImageUrlOf(product.images);

              return Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index < _related.length - 1 ? 16 : 0,
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/product-detail',
                    arguments: {'product': product.toJson()},
                  ),
                  child: SizedBox(
                    width: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF1C2630) : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl == null
                                ? Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  )
                                : Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.image_outlined,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        StyledPriceText(
                          amount: product.finalPrice,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Initials for a reviewer's avatar circle. Kept out of the widget so it can
/// be tested on its own.
String initialsOfName(String name) {
  final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }
  return (words.first.substring(0, 1) + words[1].substring(0, 1))
      .toUpperCase();
}

/// The first usable picture in whatever shape the API sent the images in.
String? firstImageUrlOf(List<dynamic> images) {
  for (final image in images) {
    if (image is String && image.trim().isNotEmpty) return image;
    if (image is Map) {
      final url = image['url']?.toString() ??
          image['path']?.toString() ??
          image['image']?.toString() ??
          '';
      if (url.trim().isNotEmpty) return url;
    }
  }
  return null;
}

/// Numbers arrive as strings or as numbers depending on the endpoint, and a
/// recorded zero means "never measured" rather than a real measurement, so it
/// is left off the specifications instead of reading as "0".
String? formatMeasure(dynamic raw) {
  if (raw == null) return null;
  final text = raw.toString().trim();
  if (text.isEmpty) return null;
  final number = double.tryParse(text);
  if (number == null) return text;
  if (number <= 0) return null;
  // Drop a trailing ".0", so 250.0 reads as 250.
  return number == number.roundToDouble()
      ? number.toStringAsFixed(0)
      : number.toString();
}

/// Length, width and height as "20 × 10 × 5", skipping whatever was
/// not measured.
String? formatDimensions(dynamic raw) {
  if (raw is! Map) return null;
  final parts = [
    formatMeasure(raw['length']),
    formatMeasure(raw['width']),
    formatMeasure(raw['height']),
  ].whereType<String>().toList();
  if (parts.isEmpty) return null;
  return parts.join(' × ');
}
