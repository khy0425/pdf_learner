import 'dart:async';
import 'dart:typed_data';

class Event {
  final String type;

  Event(this.type);
}

class Element {
  String? type;
  String? value;
  bool? checked;
  bool? disabled;
  bool? multiple;
  String? accept;
  List<File>? files;
  String? href;
  String? id;
  String? name;
}

class Document {
  final Body body;

  Document() : body = Body();

  Element createElement(String tagName) {
    switch (tagName) {
      case 'div':
        return DivElement();
      case 'iframe':
        return IFrameElement();
      case 'input':
        return InputElement();
      case 'canvas':
        return CanvasElement();
      case 'a':
        return AnchorElement();
      default:
        return Element();
    }
  }
}

class Location {
  String href = '';
}

class Navigator {
  final Clipboard clipboard = Clipboard();
}

class Plugin {
  final String name;
  final String description;
  final String filename;

  Plugin({
    required this.name,
    required this.description,
    required this.filename,
  });
}

class Body {
  final List<Element> children = [];

  void add(Element child) {
    children.add(child);
  }

  void remove(Element child) {
    children.remove(child);
  }
}

class DivElement extends Element {}

class IFrameElement extends Element {}

class InputElement extends Element {
  InputElement() {
    type = 'text';
    value = '';
    checked = false;
    disabled = false;
    multiple = false;
    accept = '';
    files = [];
  }
}

class CanvasElement extends Element {}

class AnchorElement extends Element {
  AnchorElement() {
    href = '';
  }
}

class File {
  final String name;
  final String type;
  final int size;
  final DateTime lastModified;

  File({
    required this.name,
    required this.type,
    required this.size,
    required this.lastModified,
  });
}

class Clipboard {
  Future<void> writeText(String text) async {}
}

class Window {
  final Document document = Document();
  final Location location = Location();
  final Navigator navigator = Navigator();
}

final window = Window(); 