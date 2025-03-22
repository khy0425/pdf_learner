class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }

  factory Rect.fromJson(Map<String, dynamic> json) {
    return Rect(
      left: json['left'] as double,
      top: json['top'] as double,
      right: json['right'] as double,
      bottom: json['bottom'] as double,
    );
  }

  @override
  String toString() {
    return 'Rect(left: $left, top: $top, right: $right, bottom: $bottom)';
  }
} 