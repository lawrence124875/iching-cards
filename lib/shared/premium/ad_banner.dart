import 'package:flutter/material.dart';

import '../../app/services.dart';

/// 頁面底部橫幅（免費版）。訂閱戶、沒有廣告時不佔任何空間。
/// 只放在首頁與卦記列表；**呼吸頁、解讀頁不放**（§21.1，不打擾靜心與閱讀）。
/// 放在 Scaffold.bottomNavigationBar 時，Scaffold 會把底部系統列的高度從 body 拿掉、交給這裡處理，
/// 所以一定要包 SafeArea：沒有廣告（會員）時也要留出三鍵導覽列的高度，否則首頁免責聲明會被蓋住。
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) =>
      SafeArea(top: false, child: AppServices.of(context).ads.banner() ?? const SizedBox.shrink());
}
