import 'dart:convert';

import '../presentation/formpage_screen.dart';

List<Question> questionsFromJson(String jsonString) {
  final List<Map<String, dynamic>> jsonList = List<Map<String, dynamic>>.from(json.decode(jsonString));
  return jsonList.map((json) {
    if (json['type'] == 'dropdown') {
      List<dynamic> items = json['items'];
      Set<dynamic> uniqueItems = Set<dynamic>.from(items);
      if (items.length != uniqueItems.length) {
        throw Exception('Dropdown items must have unique values');
      }
      List<Map<String, dynamic>> mappedItems = items
          .map((item) => {'value': item, 'id': items.indexOf(item)})
          .toList();
      return Question(
        qid: json['qid'],
        label: json['label'],
        type: json['type'],
        items: mappedItems,
        range: json['range'] != null ? List<int>.from(json['range']) : const <int>[],
      );
    } else {
      return Question(
        qid: json['qid'],
        label: json['label'],
        type: json['type'],
        items: json['items'],
        range: json['range'] != null ? List<int>.from(json['range']) : const <int>[],
      );
    }
  }).toList();
}

String jsonString = '[{"qid":1,"label":"construction_material","type":"dropdown","items":["masonry","adobe","reinforced_concrete_porticoes","reinforced_concrete_walls","reinforced_concrete_prefab","wood","metallic"]},{"qid":2,"label":"construction_period","type":"dropdown","items":["before_1960","1960_1985","1985_2000","2000_2010","after_2010"]},{"qid":3,"label":"number_storeys","type":"number","range":[1,100]},{"qid":4,"label":"basements","type":"dropdown","items":["yes","no","dontknow"]},{"qid":5,"label":"entrance_height","type":"number","range":[0,250]},{"qid":6,"label":"occupation_type","type":"dropdown","items":["residential","residential_commercial","commercial","industrial","public","education","health","other"]},{"qid":7,"label":"position","type":"dropdown","items":["adjacent_building_one_side","adjacent_building_two_side","isolated"]},{"qid":8,"label":"number_small_windows","type":"number","range":[0,250]},{"qid":9,"label":"number_big_windows","type":"number","range":[0,250]},{"qid":10,"label":"number_doors","type":"number","range":[0,50]},{"qid":11,"label":"number_balconies","type":"number","range":[0,50]},{"qid":12,"label":"number_chimneys","type":"number","range":[0,50]},{"qid":13,"label":"vertical_irregularities","type":"dropdown","items":["soft_storey","vertical_change","pounding","other"]},{"qid":14,"label":"horizontal_irregularities","type":"dropdown","items":["potential_torsion","other"]},{"qid":15,"label":"roof_type","type":"dropdown","items":["flat","inclined_ceramic","inclined_sandwich","oth"]},{"qid":16,"label":"comment","type":"largetext"}]';

List<Question> questions = questionsFromJson(jsonString);


