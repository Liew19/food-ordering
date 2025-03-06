import 'package:hive/hive.dart';
import '../menu_item.dart';

class MenuItemAdapter extends TypeAdapter<MenuItem> {
  @override
  final int typeId = 1;

  @override
  MenuItem read(BinaryReader reader) {
    // The order of reading serialized data must match the writing order
    return MenuItem(
      itemId: reader.readString(),
      name: reader.readString(),
      price: reader.readDouble(),
      category: reader.readString(),
      imageUrl: reader.readString(),
      id: '',
      preparationTime: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, MenuItem obj) {
    // Write all properties in a fixed order
    writer.writeString(obj.itemId);
    writer.writeString(obj.name);
    writer.writeDouble(obj.price);
    writer.writeString(obj.category);
    writer.writeString(obj.imageUrl);
    writer.writeDouble(obj.preparationTime);
  }
}
