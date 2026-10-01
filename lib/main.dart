import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppServices(services: Services.standard(), child: const IchingApp()));
}
