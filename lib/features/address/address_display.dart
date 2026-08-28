String formatAddressForCell(String address, double textScaleFactor) {
  var prefix = '';
  var body = address;

  if (address.startsWith('0x')) {
    prefix = '0x';
    body = address.substring(2);
  }

  if (body.length <= 12) {
    return address;
  }

  final startLength = textScaleFactor >= 1.6 ? 4 : 6;
  const endLength = 4;

  final start = body.substring(0, startLength);
  final end = body.substring(body.length - endLength);

  return '$prefix$start…$end';
}
