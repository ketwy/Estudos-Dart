import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// Interface Observer
abstract class Observer {
  void update();
}

// Observador Concreto
class TableObserver implements Observer {
  final Function updateCallback;

  TableObserver(this.updateCallback);

  @override
  void update() {
    updateCallback();
  }
}

class DataService {
  final ValueNotifier<List> tableStateNotifier = ValueNotifier([]);
  final ValueNotifier<List<String>> columnNamesNotifier = ValueNotifier([]);
  final ValueNotifier<List<String>> propertyNamesNotifier = ValueNotifier([]);
  int _querySize = 5;
  final List<Observer> observers = [];

  void setQuerySize(int newSize) {
    _querySize = newSize;
  }

  void attachObserver(Observer observer) {
    observers.add(observer);
  }

  void detachObserver(Observer observer) {
    observers.remove(observer);
  }

  void notifyObservers() {
    for (final observer in observers) {
      observer.update();
    }
  }

  void carregar(index) {
    if (index == 0) carregarCafes();
    if (index == 1) carregarCervejas();
    if (index == 2) carregarNacoes();
  }

  DataService() {
    carregarCervejas();
  }

  Future<void> carregarCervejas() async {
    var beersUri = Uri(
        scheme: 'https',
        host: 'random-data-api.com',
        path: 'api/beer/random_beer',
        queryParameters: {'size': '$_querySize'});

    var jsonString = await http.read(beersUri);

    var beersJson = jsonDecode(jsonString);

    tableStateNotifier.value = beersJson;
    propertyNamesNotifier.value = ["name", "style", "ibu"];
    columnNamesNotifier.value = ["Nome", "Estilo", "IBU"];
    notifyObservers();
  }

  Future<void> carregarCafes() async {
    var coffesUri = Uri(
        scheme: 'https',
        host: 'random-data-api.com',
        path: 'api/coffee/random_coffee',
        queryParameters: {'size': '$_querySize'});

    var jsonString = await http.read(coffesUri);

    var coffesJson = jsonDecode(jsonString);

    tableStateNotifier.value = coffesJson;
    propertyNamesNotifier.value = ["blend_name", "origin", "intensifier"];
    columnNamesNotifier.value = ["Nome do Mix", "Origem", "Intensidade"];
    notifyObservers();
  }

  Future<void> carregarNacoes() async {
    var nationsUri = Uri(
        scheme: 'https',
        host: 'random-data-api.com',
        path: 'api/nation/random_nation',
        queryParameters: {'size': '$_querySize'});

    var jsonString = await http.read(nationsUri);

    var nationsJson = jsonDecode(jsonString);

    tableStateNotifier.value = nationsJson;
    propertyNamesNotifier.value = ["nationality", "language", "capital"];
    columnNamesNotifier.value = ["Nação", "Idioma", "Capital"];
    notifyObservers();
  }
}

final dataService = DataService();

void main() {
  MyApp app = const MyApp();

  runApp(app);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Dicas"),
          actions: [
            PopupMenuButton<int>(
              onSelected: (int newSize) {
                dataService.setQuerySize(newSize);
              },
              itemBuilder: (BuildContext context) => const [
                PopupMenuItem<int>(
                  value: 5,
                  child: Text('Size: 5'),
                ),
                PopupMenuItem<int>(
                  value: 10,
                  child: Text('Size: 10'),
                ),
                PopupMenuItem<int>(
                  value: 15,
                  child: Text('Size: 15'),
                ),
              ],
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: dataService.tableStateNotifier,
          builder: (_, value, __) {
            if (value.isEmpty) {
              return const SpinKitSpinningLines(color: Colors.blueAccent);
            }
            return DataTableWidget(jsonObjects: value);
          },
        ),
        bottomNavigationBar:
            NewNavBar(itemSelectedCallback: dataService.carregar),
      ),
    );
  }
}

class NewNavBar extends HookWidget {
  final Function(int) itemSelectedCallback;

  const NewNavBar({required this.itemSelectedCallback});

  @override
  Widget build(BuildContext context) {
    var state = useState(1);

    useEffect(() {
      final observer = TableObserver(() {
        state.value = 0; // Reset selected index when data changes
      });
      dataService.attachObserver(observer);

      return () {
        dataService.detachObserver(observer);
      };
    }, []);

    return BottomNavigationBar(
      onTap: (index) {
        state.value = index;
        itemSelectedCallback(index);
      },
      currentIndex: state.value,
      items: const [
        BottomNavigationBarItem(
          label: "Cafés",
          icon: Icon(Icons.coffee_outlined),
        ),
        BottomNavigationBarItem(
          label: "Cervejas",
          icon: Icon(Icons.local_drink_outlined),
        ),
        BottomNavigationBarItem(
          label: "Nações",
          icon: Icon(Icons.flag_outlined),
        ),
      ],
    );
  }
}

class DataTableWidget extends StatelessWidget {
  final List jsonObjects;

  DataTableWidget({required this.jsonObjects});

  @override
  Widget build(BuildContext context) {
    final columnNames = dataService.columnNamesNotifier.value;
    final propertyNames = dataService.propertyNamesNotifier.value;
    return ListView(
      children: [
        DataTable(
          columns: columnNames
              .map(
                (name) => DataColumn(
                  label: Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              )
              .toList(),
          rows: jsonObjects
              .map(
                (obj) => DataRow(
                  cells: propertyNames
                      .map(
                        (propName) => DataCell(Text(obj[propName])),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
