import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

String getLocalizedLabel(String key, BuildContext context) {
  switch (key) {
    case 'construction_material':
      return AppLocalizations.of(context)!.construction_material;
    case 'construction_period':
      return AppLocalizations.of(context)!.construction_period;
    case 'number_storeys':
      return AppLocalizations.of(context)!.number_storeys;
    case 'basements':
      return AppLocalizations.of(context)!.basements;
    case 'entrance_height':
      return AppLocalizations.of(context)!.entrance_height;
    case 'occupation_type':
      return AppLocalizations.of(context)!.occupation_type;
    case 'position':
      return AppLocalizations.of(context)!.position;
    case 'number_small_windows':
      return AppLocalizations.of(context)!.number_small_windows;
    case 'number_big_windows':
      return AppLocalizations.of(context)!.number_big_windows;
    case 'number_doors':
      return AppLocalizations.of(context)!.number_doors;
    case 'number_balconies':
      return AppLocalizations.of(context)!.number_balconies;
    case 'number_chimneys':
      return AppLocalizations.of(context)!.number_chimneys;
    case 'vertical_irregularities':
      return AppLocalizations.of(context)!.vertical_irregularities;
    case 'horizontal_irregularities':
      return AppLocalizations.of(context)!.horizontal_irregularities;
    case 'roof_type':
      return AppLocalizations.of(context)!.roof_type;
    case 'comment':
      return AppLocalizations.of(context)!.comment;
    default:
      return '';
  }
}

String getLocalizedValue(String key, BuildContext context) {
  switch (key) {
    case "masonry":
      return AppLocalizations.of(context)!.masonry;
    case "adobe":
      return AppLocalizations.of(context)!.adobe;
    case "reinforced_concrete_porticoes":
      return AppLocalizations.of(context)!.reinforced_concrete_porticoes;
    case "reinforced_concrete_walls":
      return AppLocalizations.of(context)!.reinforced_concrete_walls;
    case "reinforced_concrete_prefab":
      return AppLocalizations.of(context)!.reinforced_concrete_prefab;
    case "wood":
      return AppLocalizations.of(context)!.wood;
    case "metallic":
      return AppLocalizations.of(context)!.metallic;
    case "before_1960":
      return AppLocalizations.of(context)!.before_1960;
    case "1960_1985":
      return AppLocalizations.of(context)!.n1960_1985;
    case "1985_2000":
      return AppLocalizations.of(context)!.n1985_2000;
    case "2000_2010":
      return AppLocalizations.of(context)!.n2000_2010;
    case "after_2010":
      return AppLocalizations.of(context)!.after_2010;
    case "yes":
      return AppLocalizations.of(context)!.yes;
    case "no":
      return AppLocalizations.of(context)!.no;
    case "dontknow":
      return AppLocalizations.of(context)!.dontknow;
    case "residential":
      return AppLocalizations.of(context)!.residential;
    case "residential_commercial":
      return AppLocalizations.of(context)!.residential_commercial;
    case "commercial":
      return AppLocalizations.of(context)!.commercial;
    case "industrial":
      return AppLocalizations.of(context)!.industrial;
    case "public":
      return AppLocalizations.of(context)!.public;
    case "education":
      return AppLocalizations.of(context)!.education;
    case "health":
      return AppLocalizations.of(context)!.health;
    case "other":
      return AppLocalizations.of(context)!.other;
    case "adjacent_building_one_side":
      return AppLocalizations.of(context)!.adjacent_building_one_side;
    case "adjacent_building_two_side":
      return AppLocalizations.of(context)!.adjacent_building_two_side;
    case "isolated":
      return AppLocalizations.of(context)!.isolated;
    case "soft_storey":
      return AppLocalizations.of(context)!.soft_storey;
    case "vertical_change":
      return AppLocalizations.of(context)!.vertical_change;
    case "pounding":
      return AppLocalizations.of(context)!.pounding;
    case "potential_torsion":
      return AppLocalizations.of(context)!.potential_torsion;
    case "flat":
      return AppLocalizations.of(context)!.flat;
    case "inclined_ceramic":
      return AppLocalizations.of(context)!.inclined_ceramic;
    case "inclined_sandwich":
      return AppLocalizations.of(context)!.inclined_sandwich;
    case "oth":
      return AppLocalizations.of(context)!.oth;
    default:
      return key;
  }
}
