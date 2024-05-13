import 'package:flutter/material.dart';
import 'package:mebel_shop/Models/Product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Function onTap;
  final String imageUrl;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.imageUrl,
  }) : super(key: key);

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      IconData iconData = rating >= i + 1 ? Icons.star : Icons.star_border;
      stars.add(Icon(iconData,
          color: Colors.amber,
          size: 18)); // размер звезд подбирается под дизайн
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    var width =
        MediaQuery.of(context).size.width / 2 - 10; // Вычитаем 10 для отступов

    return GestureDetector(
      onTap: () => onTap(),
      child: Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                imageUrl,
                width: width,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${product.price} ₽',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 4),
                  _buildRatingStars(product.rating),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
