import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        "flutterone-64509-default-rtdb.firebaseio.com", "shopping-list.json");
    final response = await http.get(url);
    final Map<String, dynamic>? listData = json.decode(response.body);

    final List<GroceryItem> loadedItems = [];
    if (listData != null) {
      for (final item in listData.entries) {
        final category = categories.entries.firstWhere(
          (catItem) => catItem.value.title == item.value['category'],
        ).value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
    }

    setState(() {
      _groceryItems = loadedItems;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem != null) {
      final url = Uri.https(
          "flutterone-64509-default-rtdb.firebaseio.com", "shopping-list.json");
      final response = await http.post(
        url,
        body: json.encode({
          'name': newItem.name,
          'quantity': newItem.quantity,
          'category': newItem.category.title,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      final id = responseData['name'];

      setState(() {
        _groceryItems.add(
          GroceryItem(
            id: id,
            name: newItem.name,
            quantity: newItem.quantity,
            category: newItem.category,
          ),
        );
      });
    }
  }

  void _removeItem(GroceryItem item) async {
    final url = Uri.https(
        "flutterone-64509-default-rtdb.firebaseio.com", "shopping-list.json");
    await http.delete(url);

    setState(() {
      _groceryItems.remove(item);
    });
  }

  void _deleteItem(int index) {
    _removeItem(_groceryItems[index]);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("No items added yet!"),
    );

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            _deleteItem(index);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(onPressed: _addItem, icon: const Icon(Icons.add)),
        ],
      ),
      body: content,
    );
  }
}
