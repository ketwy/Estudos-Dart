import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

// Interface Observer
abstract class Observer {
  void update(List data);
}

// Observador Concreto
class TableObserver implements Observer {
  final Function(List) updateCallback;

  TableObserver(this.updateCallback);

  @override
  void update(List data) {
    updateCallback(data);
  }
}

// Classe DataService (Sujeito)
class DataService {
  final ValueNotifier<List> tableStateNotifier;
  final ValueNotifier<List<String>> columnNamesNotifier;
  final ValueNotifier<List<String>> propertyNamesNotifier;
  final List<Observer> observers;

  DataService()
      : tableStateNotifier = ValueNotifier([
          {"name": "La Fin Du Monde", "style": "Bock", "ibu": "65"},
          {"name": "Sapporo Premiume", "style": "Sour Ale", "ibu": "54"},
          {"name": "Duvel", "style": "Pilsner", "ibu": "82"}
        ]),
        columnNamesNotifier = ValueNotifier(["Nome", "Estilo", "IBU"]),
        propertyNamesNotifier = ValueNotifier(["name", "style", "ibu"]),
        observers = [];

  void attachObserver(Observer observer) {
    observers.add(observer);
  }

  void detachObserver(Observer observer) {
    observers.remove(observer);
  }

  void notifyObservers() {
    final data = tableStateNotifier.value;
    for (final observer in observers) {
      observer.update(data);
    }
  }

  void carregar(int index) {
    final List<Function> functions = [
      carregarCafes,
      carregarCervejas,
      carregarNacoes,
    ];
    functions[index]();
    notifyObservers();
  }

  void carregarCervejas() {
    tableStateNotifier.value = [
      {"name": "La Fin Du Monde", "style": "Bock", "ibu": "65"},
      {"name": "Sapporo Premiume", "style": "Sour Ale", "ibu": "54"},
      {"name": "Duvel", "style": "Pilsner", "ibu": "82"}
    ];
    columnNamesNotifier.value = ["Nome", "Estilo", "IBU"];
    propertyNamesNotifier.value = ["name", "style", "ibu"];
  }

  void carregarCafes() {
    tableStateNotifier.value = [
      {"name": "Blend", "quality": "Ótimo", "note": "10"},
      {"name": "Expresso", "quality": "razoavel", "note": "7"},
      {"name": "Seridó", "quality": "ruim", "note": "2"}
    ];
    columnNamesNotifier.value = ["Nome", "Qualidade", "Nota Pessoal"];
    propertyNamesNotifier.value = ["name", "quality", "note"];
  }

  void carregarNacoes() {
    tableStateNotifier.value = [
      {"name": "Brasil", "style": "Samba", "ping": "10"},
      {"name": "EUA", "style": "Rock", "ping": "3"},
      {"name": "Nova Zelandia", "style": "blues", "ping": "8"}
    ];
    columnNamesNotifier.value = ["Nome", "Estilo Musical", "Nota da Pinga"];
    propertyNamesNotifier.value = ["name", "style", "ping"];
  }
}

final dataService = DataService();

void main() {
  MyApp app = MyApp();

  runApp(app);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            title: const Text("Dicas"),
          ),
          body: ValueListenableBuilder(
              valueListenable: dataService.tableStateNotifier,
              builder: (_, value, __) {
                return DataTableWidget(
                  jsonObjects: value,
                );
              }),
          bottomNavigationBar:
              NewNavBar(itemSelectedCallback: dataService.carregar),
        ));
  }
}

class NewNavBar extends HookWidget {
  final Function(int) itemSelectedCallback;

  NewNavBar({required this.itemSelectedCallback});

  @override
  Widget build(BuildContext context) {
    var state = useState(1);

    useEffect(() {
      final observer = TableObserver((data) {
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
              label: "Cervejas", icon: Icon(Icons.local_drink_outlined)),
          BottomNavigationBarItem(
              label: "Nações", icon: Icon(Icons.flag_outlined))
        ]);
  }
}

class DataTableWidget extends StatelessWidget {
  final List jsonObjects;

  DataTableWidget({required this.jsonObjects});

  @override
  Widget build(BuildContext context) {
    final columnNames = dataService.columnNamesNotifier.value;
    final propertyNames = dataService.propertyNamesNotifier.value;
    return DataTable(
      columns: columnNames
          .map((name) => DataColumn(
              label: Expanded(
                  child: Text(name,
                      style: const TextStyle(fontStyle: FontStyle.italic)))))
          .toList(),
      rows: jsonObjects
          .map((obj) => DataRow(
              cells: propertyNames
                  .map((propName) => DataCell(Text(obj[propName])))
                  .toList()))
          .toList(),
    );
  }
}
