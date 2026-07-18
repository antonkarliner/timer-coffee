int? celsiusToFahrenheit(double? celsius) {
  if (celsius == null) return null;
  return (celsius * 9 / 5 + 32).round();
}

String _formatCelsius(double celsius) {
  return celsius == celsius.roundToDouble()
      ? celsius.toStringAsFixed(0)
      : celsius.toString();
}

String? formatTemperatureChip(double? celsius) {
  if (celsius == null) return null;
  return '${_formatCelsius(celsius)}°';
}

String? formatTemperatureDual(double? celsius) {
  final fahrenheit = celsiusToFahrenheit(celsius);
  if (celsius == null || fahrenheit == null) return null;
  return '${_formatCelsius(celsius)} °C · $fahrenheit °F';
}

String? formatTemperatureInputHelper(double? celsius) {
  final fahrenheit = celsiusToFahrenheit(celsius);
  if (fahrenheit == null) return null;
  return '= $fahrenheit °F';
}
