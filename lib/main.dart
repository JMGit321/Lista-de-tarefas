import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async/async.dart';
void main(){
  runApp(MaterialApp(
    title: "Lista de tarefas",
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List toDoList = [];
  Map<String, dynamic> lastRemove = Map();
  int idxRemove;
  TextEditingController toDoController = TextEditingController();

  @override
  void initState(){
    super.initState();
    _readData().then((data){
      setState(() {
        toDoList = jsonDecode(data);

      });

    });//chama uma funçao aqui de dentro assim que o readdata devolver os dados
  }
  Future<File> _getFile() async {//Leitura e gravamento de arquivos é assincrona
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");//caminho do direitorio
  }
  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      toDoList.sort((a,b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;

      });
      _saveData();
    });
    return null;
  }
  Future<File> _saveData() async{
    String data = json.encode(toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }
  Future<String> _readData() async{ //dentro dos parentes é o retorno
    try{
      final file = await _getFile();
      return file.readAsStringSync();
    } catch (e){
        return null;
    }
  }
  void addTodo(){
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo['title'] = toDoController.text;
      newTodo['ok'] = false;
      toDoController.text  = "";
      toDoList.add(newTodo);
      _saveData();
    });

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: Text("Lista de tarefas",style: TextStyle(
          fontSize: 25,color: Colors.white,
            ),
        ),
      ),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17,1,7,1),
              child: Row(
                children: <Widget>[
                  Expanded( //Sem isso o programa fica doido em relação ao botao e ao texto
                    child: TextField(
                      controller: toDoController,
                      textAlign: TextAlign.left,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Tarefa",
                        labelStyle: TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  RaisedButton(
                    onPressed: addTodo,
                    color: Colors.blue,
                    child: Text("ADD",),
                    textColor: Colors.white,
                  )
                ],
              ),
            ),
            Expanded(
             child: RefreshIndicator(onRefresh: _refresh,
               child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: toDoList.length,
                  itemBuilder: buildItem),
             ),
            )
          ],
        ),
      );

  }
  Widget buildItem (context,index){
  return Dismissible(
    key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
    background: Container(
      color: Colors.red,
      child: Align(
        alignment: Alignment(-0.9,0),
        child: Icon(
            Icons.delete,
          color: Colors.white,
        ),
      ),
    ),
    direction: DismissDirection.startToEnd, //direção do dismissible da esquerda pra direita
    child: CheckboxListTile(
      title: Text(toDoList[index]['title']),
      value: toDoList[index]["ok"],
      secondary: CircleAvatar(
        child: Icon(
          toDoList[index]["ok"] ? Icons.check : Icons.error,
        ),
      ),
      onChanged: (check){//aqui no check é true por padrao
        setState(() {
          toDoList[index]['ok'] = check;
          _saveData();
        });
      },
    ),
    onDismissed: (direction){
      setState(() {
        lastRemove = Map.from(toDoList[index]);
        idxRemove = index;
        toDoList.removeAt(index);
        _saveData();
        final snack = SnackBar(
          content: Text("Tarefa \"${lastRemove['title']} removida!"),
          action: SnackBarAction(label: "Desfazer", onPressed: (){
            setState(() {
              toDoList.insert(idxRemove, lastRemove);
              _saveData();
            });

          }),
          duration: Duration(seconds: 5),
        );
        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      });

    } ,//função chamada quando arrasta o item pra remover
  );
  }
}


