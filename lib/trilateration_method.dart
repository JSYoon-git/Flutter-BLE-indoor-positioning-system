import 'package:matrix2d/matrix2d.dart';
import 'dart:math';

class Anchor {
  double centerX;
  double centerY;
  double radius;

  Anchor({required this.centerX, required this.centerY, required this.radius});
}

List trilaterationMethod(List<Anchor> anchorList, double maxDistance) {
  var matrixA = [];
  var matrixB = [];
  const Matrix2d m2d = Matrix2d();

  for (int idx = 1; idx <= anchorList.length - 1; idx++) {
    // value A
    matrixA.add([
      anchorList[idx].centerX - anchorList[0].centerX,
      anchorList[idx].centerY - anchorList[0].centerY
    ]);
    // value b
    matrixB.add([
      ((pow(anchorList[idx].centerX, 2) +
                  pow(anchorList[idx].centerY, 2) -
                  pow(
                      anchorList[idx].radius > maxDistance
                          ? maxDistance
                          : anchorList[idx].radius,
                      2)) -
              (pow(anchorList[0].centerX, 2) +
                  pow(anchorList[0].centerY, 2) -
                  pow(
                      anchorList[0].radius > maxDistance
                          ? maxDistance
                          : anchorList[0].radius,
                      2))) /
          2
    ]);
  }
  var matrixATranspose = transposeDouble(matrixA);
  var matrixInverse = dim2InverseMatrix(m2d.dot(matrixATranspose, matrixA));
  var matrixDot = m2d.dot(matrixInverse, matrixATranspose);
  var position = m2d.dot(matrixDot, matrixB);
  return position;
}

// matrix transpose
List transposeDouble(List list) {
  var shape = list.shape;
  var temp = List.filled(shape[1], 0.0)
      .map((e) => List.filled(shape[0], 0.0))
      .toList();
  for (var i = 0; i < shape[1]; i++) {
    for (var j = 0; j < shape[0]; j++) {
      temp[i][j] = list[j][i];
    }
  }
  return temp;
}

// inverse matrix
List dim2InverseMatrix(List list) {
  var shape = list.shape;
  var temp = List.filled(shape[1], 0.0)
      .map((e) => List.filled(shape[0], 0.0))
      .toList();
  var determinant = list[0][0] * list[1][1] - list[1][0] * list[0][1];
  temp[0][0] = list[1][1] / determinant;
  temp[0][1] = -list[0][1] / determinant;
  temp[1][0] = -list[1][0] / determinant;
  temp[1][1] = list[0][0] / determinant;

  return temp;
}
