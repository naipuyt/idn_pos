import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:idn_pos/models/products.dart';
import 'package:idn_pos/screens/cashier/components/checkout_panel.dart';
import 'package:idn_pos/screens/cashier/components/printer_selector.dart';
import 'package:idn_pos/screens/cashier/components/product_card.dart';
import 'package:idn_pos/screens/cashier/components/qr_result_modal.dart';
import 'package:idn_pos/utils/currency_format.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  final Map<Product, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  // LOGIKA BLUETOOTH
  Future<void> _initBluetooth() async {
    // meminta izin lokasi & bluetooth (Wajib)
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    List<BluetoothDevice> devices = [
      // list ini akan otomatis terisi, jika BT di handphone menyala, dan sudah ada device yang siap dikoneksikan
    ];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint("Error Bluetooth: $e");
    }

    if (mounted) {
      setState(() {
        _devices = devices;
      });
    }

    bluetooth.onStateChanged().listen((state) {
      if (mounted) {
        setState(() {
          _connected = state == BlueThermalPrinter.CONNECTED;
        });
      }
    });
  }

  void _connectToDevice(BluetoothDevice? device) {
    // if (kondisi) utama, yang memeplopori if-if selanjutnya
    if (device != null) {
      bluetooth.isConnected.then((isConnected) {
        // if yang merupakan anak/cabang dari if utama,
        // if ini memiliki sebuah kondisi yang menjawab pertanyaan/statement dari kondisi utama
        if (isConnected == false) {
          bluetooth.connect(device).catchError((error) {
            // if ini wajib memiliki opini yang sama, seperti if kedua
            if (mounted) setState(() => _connected = false);
          });

          // statement di dalam if ini, akan dijalankan, ketika if-if sebelumnya tidak terpenuhi
          // if ini adalah opsi terakhir yang akan dijalankan, ketika if-if sebelumnya tidak terpenuhi (tidak berjalan)
          if (mounted) setState(() => _selectedDevice = device);
        }
      });
    }
  }

  // LOGIKA CART
  void _addToCart(Product product) {
    setState(() {
      _cart.update(
        // untuk mendefinisikan produk yang ada di menu
        product,
        // logika matematis, yang dijalankan ketika satu produk sudah berada di keranjang, dan user klik +, yang nantinya jumlahnya akan ditambah 1
        (value) => value + 1,
        // jika user tidak menambahkan lagi jumlah produk (jumlah hanya 1) di keranjang, maka default jumlah dari barang tersebut adalah 1
        ifAbsent: () => 1,
      );
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      if (_cart.containsKey(product) && _cart[product]! > 1) {
        _cart[product] = _cart[product]! - 1;
      } else {
        _cart.remove(product);
      }
    });
  }

  int _calculateTotal() {
    int total = 0;
    _cart.forEach((key, value) => total += (key.price * value));
    return total;
  }

  // LOGIKA PRINTING
  void _handlePrint() async {
    int total = _calculateTotal();
    if (total == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Keranjang masih kosong!")));
    }

    String trxId =
        "TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    String qrData = "PAY:$trxId:$total";
    bool isPrinting = false;

    // menyiapkan tanggal saat ini (current date)
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(now);

    // LAYOUTING STRUK
    if (_selectedDevice != null && await bluetooth.isConnected == true) {
      // header struk
      bluetooth.printNewLine();
      bluetooth.printCustom("IDN CAFE", 3, 1); // judul besar (center)
      bluetooth.printNewLine();
      bluetooth.printCustom("Jl. Bagus Dayeuh", 1, 1); // alamat (center)

      // tanggal & ID
      bluetooth.printNewLine();
      bluetooth.printLeftRight("Waktu:", formattedDate, 1);

      // daftar items
      bluetooth.printCustom("--------------------------------", 1, 1);
      _cart.forEach((product, qty) {
        String priceTotal = formatRupiah(product.price * qty);
        // cetak nama barang x qty
        // ignore: unnecessary_brace_in_string_interps
        bluetooth.printLeftRight("${product.name} x${qty}", priceTotal, 1);
      });
      bluetooth.printCustom("--------------------------------", 1, 1);

      // total & QR
      bluetooth.printLeftRight("TOTAL", formatRupiah(total), 3);
      bluetooth.printNewLine();
      bluetooth.printCustom("Scan QR Di Bawah:", 1, 1);
      bluetooth.printQRcode(qrData, 200, 200, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Thank You", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();

      isPrinting = true;
    }

    // untuk menampilkan modal hasil QR Code (PopUp)
    _showQRModal(qrData, total, isPrinting);
  }

  void _showQRModal(String qrData, int total, bool isPrinting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrResultModal(
        qrData: qrData,
        total: total,
        isPrinting: isPrinting,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Menu Kasir",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Column(
  children: [
    // 1️⃣ PRINTER SELECTOR
    SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: PrinterSelector(
          devices: _devices,
          selectedDevice: _selectedDevice,
          isConnected: _connected,
          onSelected: _connectToDevice,
        ),
      ),
    ),

    // 2️⃣ GRID MENU
    Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: menus.length,
        itemBuilder: (context, index) {
          final product = menus[index];
          final qty = _cart[product] ?? 0;

          return ProductCard(
            product: product,
            qty: qty,
            onAdd: () => _addToCart(product),
            onRemove: () => _removeFromCart(product),
          );
        },
      ),
    ),

    // 3️⃣ CHECKOUT
    CheckoutPanel(
      total: _calculateTotal(),
      onPressed: _handlePrint,
    ),
  ],
),

    );
  }
}
