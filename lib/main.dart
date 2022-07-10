import 'package:flutter/material.dart';
import 'package:bottom_bar/bottom_bar.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rolling_switch/rolling_switch.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';
import 'package:get/get.dart';

import 'trilateration_paint.dart';
import 'ble_data.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BLEProjectPage(title: 'Indoor Position using BLE'),
    );
  }
}

/* First Page */
class BLEProjectPage extends StatefulWidget {
  const BLEProjectPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<BLEProjectPage> createState() => _BLEProjectPageState();
}

class _BLEProjectPageState extends State<BLEProjectPage> {
  var bleController = Get.put(BLEResult());

  // page bleController
  int _currentBody = 0;
  final _pageController = PageController();
  TextEditingController textController = TextEditingController();

  // flutter_blue_plus
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  bool isScanning = false;
  int scanMode = 1;

  //BLEResult bleResult = BLEResult();

  // BLE value
  String deviceName = '';
  String macAddress = '';
  String rssi = '';
  String serviceUUID = '';
  String manuFactureData = '';
  String tp = '';

  // log distance path loss model
  double constantN = 2;
  int alpha = -59;

  // filter
  double alphaFilter = 0.7;

  var _tabScanModeIndex = 1;
  final _scanModeList = ['Low Power', 'Balanced', 'Low Latency'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: Icon(isScanning ? Icons.stop : Icons.search),
              onPressed: () {
                toggleState();
              },
            )
          ],
        ),
        body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              isScanning ? pageBLEScan() : selectScanMode(),
              pageBLESelected(),
              const CircleRoute(),
              Container(color: Colors.orange)
            ]),
        bottomNavigationBar: BottomBar(
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          selectedIndex: _currentBody,
          onTap: (int index) {
            _pageController.jumpToPage(index);
            setState(() => _currentBody = index);
          },
          items: <BottomBarItem>[
            BottomBarItem(
              icon: const Icon(Icons.bluetooth),
              title: const Text('BLE Scan'),
              activeColor: Colors.blue,
              activeTitleColor: Colors.blue.shade600,
            ),
            BottomBarItem(
              icon: const Icon(Icons.map),
              title: const Text('Anchor'),
              backgroundColorOpacity: 0.1,
              activeColor: Colors.blueAccent.shade700,
            ),
            BottomBarItem(
              icon: const Icon(Icons.place),
              title: const Text('Indoor Map'),
              backgroundColorOpacity: 0.1,
              activeColor: Colors.redAccent.shade700,
            ),
          ],
        ));
  }

  /* start or stop callback */
  void toggleState() {
    isScanning = !isScanning;
    if (isScanning) {
      flutterBlue.startScan(
          scanMode: ScanMode(scanMode), allowDuplicates: true);
      scan();
    } else {
      flutterBlue.stopScan();
      bleController.initBLEList();
    }
    setState(() {});
  }

  /* Scan */
  void scan() async {
    // Listen to scan results
    flutterBlue.scanResults.listen((results) {
      // do something with scan results
      bleController.scanResultList = results;
      // update state
      setState(() {});
    });
  }

  /* BLE Scan Page */
  Center pageBLEScan() => Center(
        child:
            /* listview */
            ListView.separated(
                itemCount: bleController.scanResultList.length,
                itemBuilder: (context, index) =>
                    widgetBLEList(index, bleController.scanResultList[index]),
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider()),
      );

  /* Selected BLE Scan Page */
  Center pageBLESelected() => Center(
        child:
            /* listview */
            ListView.separated(
                itemCount: bleController.selectedDeviceIdxList.length,
                itemBuilder: (context, index) => widgetSelectedBLEList(
                      index,
                      bleController.scanResultList[
                          bleController.selectedDeviceIdxList[index]],
                    ),
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider()),
      );

  /* listview widget for ble data */
  Widget widgetSelectedBLEList(int currentIdx, ScanResult r) {
    toStringBLE(r);
    if (bleController.filterFlagList[currentIdx]) {
      rssi = rssiFilter(
        rssi,
        bleController.previousValue[currentIdx],
      );
    }
    bleController.previousValue[currentIdx] = r.rssi;
    bleController.updateBLEList(
        deviceName: deviceName,
        macAddress: macAddress,
        rssi: rssi,
        serviceUUID: serviceUUID,
        manuFactureData: manuFactureData,
        tp: tp);

    num distance = logDistancePathLoss(rssi);
    bleController.selectedDistanceList[currentIdx] = distance;
    String constN = bleController.selectedConstNList[currentIdx].toString();
    String rssi1m = bleController.selectedRSSI_1mList[currentIdx].toString();
    return ExpansionTile(
      //leading: leading(r),
      title: Text('$deviceName ($macAddress)',
          style: const TextStyle(color: Colors.black)),
      subtitle: Text(
          '\n Alias : Anchor$currentIdx\n N : $constN\n RSSI at 1m : ${rssi1m}dBm',
          style: const TextStyle(color: Colors.blueAccent)),
      trailing: Text('${distance.toStringAsPrecision(3)}m',
          style: const TextStyle(color: Colors.black)),
      children: <Widget>[
        ListTile(
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
                  Widget>[
            Padding(
                padding: const EdgeInsets.all(16),
                child: SpinBox(
                  min: 2.0,
                  max: 4.0,
                  value:
                      bleController.selectedConstNList[currentIdx].toDouble(),
                  decimals: 1,
                  step: 0.1,
                  onChanged: (value) =>
                      bleController.selectedConstNList[currentIdx] = value,
                  decoration: const InputDecoration(
                      labelText:
                          'N (Constant depends on the Environmental factor)'),
                )),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SpinBox(
                min: -100,
                max: -30,
                value: bleController.selectedRSSI_1mList[currentIdx].toDouble(),
                decimals: 0,
                step: 1,
                onChanged: (value) => bleController
                    .selectedRSSI_1mList[currentIdx] = value.toInt(),
                decoration: const InputDecoration(labelText: 'RSSI at 1m'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SpinBox(
                min: 0.0,
                max: 20.0,
                value: bleController.selectedCenterXList[currentIdx].toDouble(),
                decimals: 1,
                step: 0.1,
                onChanged: (value) =>
                    bleController.selectedCenterXList[currentIdx] = value,
                decoration: const InputDecoration(labelText: 'Center X [m]'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SpinBox(
                min: 0.0,
                max: 20.0,
                value: bleController.selectedCenterYList[currentIdx].toDouble(),
                decimals: 1,
                step: 0.1,
                onChanged: (value) =>
                    bleController.selectedCenterYList[currentIdx] = value,
                decoration: const InputDecoration(labelText: 'Center Y [m]'),
              ),
            ),
            Row(
              children: [
                const Spacer(),
                RollingSwitch.icon(
                  initialState: bleController.filterFlagList[currentIdx],
                  onChanged: (bool state) {
                    bleController.filterFlagList[currentIdx] = state;
                  },
                  rollingInfoRight: const RollingIconInfo(
                    icon: Icons.flag,
                    text: Text(
                      'Filter',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  rollingInfoLeft: const RollingIconInfo(
                    icon: Icons.check,
                    backgroundColor: Colors.grey,
                    text: Text('Raw'),
                  ),
                )
              ],
            ),
          ]),
        )
      ],
    );
  }

  /* listview widget for ble data */
  Widget widgetBLEList(int index, ScanResult r) {
    toStringBLE(r);

    bleController.updateBLEList(
        deviceName: deviceName,
        macAddress: macAddress,
        rssi: rssi,
        serviceUUID: serviceUUID,
        manuFactureData: manuFactureData,
        tp: tp);

    serviceUUID.isEmpty ? serviceUUID = 'null' : serviceUUID;
    manuFactureData.isEmpty ? manuFactureData = 'null' : manuFactureData;
    bool switchFlag = bleController.flagList[index];
    switchFlag ? deviceName = '$deviceName (active)' : deviceName;

    bleController.updateselectedDeviceIdxList();

    return ExpansionTile(
      leading: leading(r),
      title: Text(deviceName,
          style:
              TextStyle(color: switchFlag ? Colors.lightBlue : Colors.black)),
      subtitle: Text(macAddress,
          style:
              TextStyle(color: switchFlag ? Colors.lightBlue : Colors.black)),
      trailing: Text(rssi,
          style:
              TextStyle(color: switchFlag ? Colors.lightBlue : Colors.black)),
      children: <Widget>[
        ListTile(
          title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'UUID : $serviceUUID\nManufacture data : $manuFactureData\nTX power : ${tp == 'null' ? tp : '${tp}dBm'}',
                  style: const TextStyle(fontSize: 10),
                ),
                const Padding(padding: EdgeInsets.all(2)),
                Row(
                  children: [
                    const Spacer(),
                    RollingSwitch.icon(
                      initialState: bleController.flagList[index],
                      onChanged: (bool state) {
                        bleController.updateFlagList(flag: state, index: index);
                      },
                      rollingInfoRight: const RollingIconInfo(
                        icon: Icons.flag,
                        text: Text(
                          'Active',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      rollingInfoLeft: const RollingIconInfo(
                        icon: Icons.check,
                        backgroundColor: Colors.grey,
                        text: Text('Inactive'),
                      ),
                    )
                  ],
                ),
              ]),
        )
      ],
    );
  }

  /* string */
  void toStringBLE(ScanResult r) {
    deviceName = deviceNameCheck(r);
    macAddress = r.device.id.id;
    rssi = r.rssi.toString();

    serviceUUID = r.advertisementData.serviceUuids
        .toString()
        .toString()
        .replaceAll('[', '')
        .replaceAll(']', '');
    manuFactureData = r.advertisementData.manufacturerData
        .toString()
        .replaceAll('{', '')
        .replaceAll('}', '');
    tp = r.advertisementData.txPowerLevel.toString();
  }

  /* device name check */
  String deviceNameCheck(ScanResult r) {
    String name;

    if (r.device.name.isNotEmpty) {
      // Is device.name
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      // Is advertisementData.localName
      name = r.advertisementData.localName;
    } else {
      // null
      name = 'N/A';
    }
    return name;
  }

  /* Select Scan Mode Page */
  Center selectScanMode() => Center(
          child: Column(children: <Widget>[
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(),
            TextAnimator(
              'BLE Scan Mode',
              atRestEffect: WidgetRestingEffects.pulse(effectStrength: 0.25),
              style: Theme.of(context).textTheme.headline4,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(8)),
        FlutterToggleTab(
          width: 90,
          borderRadius: 30,
          height: 50,
          selectedIndex: _tabScanModeIndex,
          selectedBackgroundColors: const [Colors.blue, Colors.blueAccent],
          selectedTextStyle: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          unSelectedTextStyle: const TextStyle(
              color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
          labels: _scanModeList,
          selectedLabelIndex: (index) {
            setState(() {
              _tabScanModeIndex = scanMode = index;
            });
          },
          isScroll: false,
        ),
        const Spacer(),
      ]));

  /* BLE icon widget */
  Widget leading(ScanResult r) => const CircleAvatar(
        backgroundColor: Colors.cyan,
        child: Icon(
          Icons.bluetooth,
          color: Colors.white,
        ),
      );

  /* log distance path loss model */
  num logDistancePathLoss(String rssi) =>
      pow(10.0, ((alpha - double.parse(rssi)) / (10 * constantN)));

  String rssiFilter(String rssi, int previousRssi) {
    return (((1 - alphaFilter) * previousRssi) +
            (alphaFilter * int.parse(rssi)))
        .toString();
  }
}
