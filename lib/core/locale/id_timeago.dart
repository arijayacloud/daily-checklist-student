import 'package:timeago/timeago.dart' as timeago;

void initializeTimeagoLocales() {
  timeago.setLocaleMessages('id', IdMessages());
}

class IdMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';

  @override
  String prefixFromNow() => 'dalam';

  @override
  String suffixAgo() => 'yang lalu';

  @override
  String suffixFromNow() => 'dari sekarang';

  @override
  String lessThanOneMinute(int seconds) => 'beberapa detik';

  @override
  String aboutAMinute(int minutes) => 'sekitar semenit';

  @override
  String minutes(int minutes) => '$minutes menit';

  @override
  String aboutAnHour(int minutes) => 'sekitar sejam';

  @override
  String hours(int hours) => '$hours jam';

  @override
  String aDay(int hours) => 'sehari';

  @override
  String days(int days) => '$days hari';

  @override
  String aboutAMonth(int days) => 'sekitar sebulan';

  @override
  String months(int months) => '$months bulan';

  @override
  String aboutAYear(int year) => 'sekitar setahun';

  @override
  String years(int years) => '$years tahun';

  @override
  String wordSeparator() => ' ';
}
