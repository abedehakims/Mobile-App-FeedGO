import 'package:hive_ce/hive_ce.dart';

part 'price_type.g.dart';

@HiveType(typeId: 3)
enum PriceType {
  @HiveField(0)
  eceran('Eceran'),
  @HiveField(1)
  grosir('Grosir'),
  @HiveField(2)
  sak('Sak');

  final String label;
  const PriceType(this.label);
}
