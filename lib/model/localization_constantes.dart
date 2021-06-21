import 'package:flutter/cupertino.dart';
import 'package:worldchat/model/DemoLocalization.dart';

String getTraducao(BuildContext context, String key){
  return DemoLocalization.of(context).getTranslatedValue(key);
}