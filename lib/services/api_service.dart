// import 'dart:convert';
// import 'package:http/http.dart' as http;
import '../models/menu_item.dart';

class ApiService {
  // If you don't need real API calls temporarily, you can use mock data
  Future<List<MenuItem>> getMenuItems() async {
    // Use delay to simulate network request
    await Future.delayed(Duration(seconds: 1));

    // Return mock data
    return [
      MenuItem(
        id: "1",
        name: "Hamburger",
        price: 35.99,
        category: "Main",
        itemId: '1',
        imageUrl:
            'https://www.foodandwine.com/thmb/DI29Houjc_ccAtFKly0BbVsusHc=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/crispy-comte-cheesburgers-FT-RECIPE0921-6166c6552b7148e8a8561f7765ddf20b.jpg',
        description:
            "Classic American burger with fresh lettuce, tomato and special sauce",
        rating: 4.8,
        isPopular: true,
        preparationTime: 10,
      ),
      MenuItem(
        id: "2",
        name: "French Fries",
        price: 18.99,
        category: "Snacks",
        itemId: '2',
        imageUrl:
            'https://sausagemaker.com/wp-content/uploads/Homemade-French-Fries_8.jpg',
        description: "Golden crispy fries, crispy outside and tender inside",
        rating: 4.5,
        preparationTime: 5,
      ),
      MenuItem(
        id: "3",
        name: "Pizza",
        price: 68.00,
        category: "Main",
        itemId: '3',
        imageUrl:
            'https://i2.wp.com/www.thursdaynightpizza.com/wp-content/uploads/2022/06/veggie-pizza-side-view-out-of-oven.png',
        description:
            "Traditional Italian thin-crust pizza with rich cheese and fresh vegetables",
        rating: 4.7,
        isPopular: true,
        preparationTime: 15,
      ),
      MenuItem(
        id: "4",
        name: "Fruit Salad with Yogurt",
        price: 28.50,
        category: "Salad",
        itemId: '4',
        imageUrl:
            'https://munchmealsbyjanet.com/wp-content/uploads/2021/04/5-Portrait-Fruit-Salad.jpg',
        description: "Seasonal fresh fruit platter with yogurt and honey",
        rating: 4.3,
        preparationTime: 8,
      ),
      MenuItem(
        id: "5",
        name: "Grilled Steak with Potato Puree",
        price: 128.00,
        category: "Main",
        itemId: '5',
        imageUrl:
            'https://natashaskitchen.com/wp-content/uploads/2020/03/Pan-Seared-Steak-4.jpg',
        description:
            "Premium beef perfectly grilled, served with seasonal vegetables and mashed potatoes",
        rating: 4.9,
        isPopular: true,
        preparationTime: 20,
      ),
      MenuItem(
        id: "6",
        name: "Chocolate Cake",
        price: 32.00,
        category: "Dessert",
        itemId: '6',
        imageUrl:
            'https://sallysbakingaddiction.com/wp-content/uploads/2019/08/chocolate-mousse-cake.jpg',
        description: "Rich and smooth chocolate cake with moist texture",
        rating: 4.6,
        preparationTime: 12,
      ),
      MenuItem(
        id: "7",
        name: "Caesar Salad with Grilled Chicken",
        price: 42.00,
        category: "Salad",
        itemId: '7',
        imageUrl:
            'https://static01.nyt.com/images/2015/06/17/dining/17PAIR2/17PAIR2-superJumbo.jpg',
        description:
            "Grilled chicken breast with fresh vegetables and Caesar dressing",
        rating: 4.4,
        preparationTime: 10,
      ),
      MenuItem(
        id: "8",
        name: "Ice Cream",
        price: 5.00,
        category: "Dessert",
        itemId: '8',
        imageUrl:
            'https://joyfoodsunshine.com/wp-content/uploads/2020/06/homemade-chocolate-ice-cream-recipe-7.jpg',
        description: "Various flavors available, rich and creamy",
        rating: 4.7,
        preparationTime: 5,
      ),
    ];
  }
}
