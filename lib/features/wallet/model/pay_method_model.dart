class PayMethodModel {
  int id;
  String name;
  bool active;
  String icon;

  PayMethodModel({
    required this.id, 
    required this.name, 
    required this.active,
    required this.icon
  });


static List<PayMethodModel> fromList(List<dynamic>? data) {
  if (data == null) return [];

  return data.map((method) {
  
    final Map<String, dynamic> item = Map<String, dynamic>.from(method);
    
    return PayMethodModel(
      id: item['id'] ?? '',
      name: item['name'] ?? 'Unknown',
      active: item['active'] ?? false,
      icon: item['icon'] ?? '',
    );
  }).toList();
}
  
}