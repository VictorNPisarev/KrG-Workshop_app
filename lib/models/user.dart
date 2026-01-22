class User
{
    final String id;
    final String email;
    final String name;
    
    User({
        required this.id,
        required this.email,
        required this.name,
    });
    
    factory User.fromJson(Map<String, dynamic> json)
    {
        print('🧩 Парсинг User из JSON: $json');
        
        return User(
            id: json['id'] as String? ?? json['Row ID'] as String? ?? '',
            email: json['Email'] as String? ?? '',
            name: json['Наименование'] as String? ?? json['Наименование'] as String? ?? 'Без имени',
        );
    }
}