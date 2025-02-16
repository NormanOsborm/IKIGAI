import 'package:flutter/cupertino.dart';

class Resposnive {
  static bool isMobile(BuildContext context){
    return MediaQuery.sizeOf(context).width<=800;
  }
  static bool isTab(BuildContext context){
    return MediaQuery.sizeOf(context).width>=800 && MediaQuery.sizeOf(context).width<=1000;
  }
  static bool isWeb(BuildContext context){
    return MediaQuery.sizeOf(context).width>=1000;
  }
}
