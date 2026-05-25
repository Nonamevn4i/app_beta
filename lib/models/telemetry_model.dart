class TelemetryData {
  final int fps;
  final double cpuUsage;
  final double cpuFreq;
  final double cpuTemp;
  final double gpuUsage;
  final double gpuFreq;
  final double gpuTemp;
  final double ramUsage;
  final double ramTotal;
  final double batteryLevel;
  final double batteryTemp;
  final double ping;
  final double downloadSpeed;
  final double uploadSpeed;
  final String throttleStatus;

  TelemetryData({
    this.fps = 0,
    this.cpuUsage = 0,
    this.cpuFreq = 0,
    this.cpuTemp = 0,
    this.gpuUsage = 0,
    this.gpuFreq = 0,
    this.gpuTemp = 0,
    this.ramUsage = 0,
    this.ramTotal = 0,
    this.batteryLevel = 0,
    this.batteryTemp = 0,
    this.ping = 0,
    this.downloadSpeed = 0,
    this.uploadSpeed = 0,
    this.throttleStatus = 'Normal',
  });

  factory TelemetryData.fromMap(Map<String, dynamic> map) {
    return TelemetryData(
      fps: (map['fps'] as num?)?.toInt() ?? 0,
      cpuUsage: (map['cpuUsage'] as num?)?.toDouble() ?? 0,
      cpuFreq: (map['cpuFreq'] as num?)?.toDouble() ?? 0,
      cpuTemp: (map['cpuTemp'] as num?)?.toDouble() ?? 0,
      gpuUsage: (map['gpuUsage'] as num?)?.toDouble() ?? 0,
      gpuFreq: (map['gpuFreq'] as num?)?.toDouble() ?? 0,
      gpuTemp: (map['gpuTemp'] as num?)?.toDouble() ?? 0,
      ramUsage: (map['ramUsage'] as num?)?.toDouble() ?? 0,
      ramTotal: (map['ramTotal'] as num?)?.toDouble() ?? 0,
      batteryLevel: (map['batteryLevel'] as num?)?.toDouble() ?? 0,
      batteryTemp: (map['batteryTemp'] as num?)?.toDouble() ?? 0,
      ping: (map['ping'] as num?)?.toDouble() ?? 0,
      downloadSpeed: (map['downloadSpeed'] as num?)?.toDouble() ?? 0,
      uploadSpeed: (map['uploadSpeed'] as num?)?.toDouble() ?? 0,
      throttleStatus: map['throttleStatus'] as String? ?? 'Normal',
    );
  }
}

class CpuCoreInfo {
  final int core;
  final int frequency;
  final int maxFrequency;
  final int minFrequency;
  final String governor;

  CpuCoreInfo({
    required this.core,
    this.frequency = 0,
    this.maxFrequency = 0,
    this.minFrequency = 0,
    this.governor = 'unknown',
  });

  factory CpuCoreInfo.fromMap(Map<String, dynamic> map) {
    return CpuCoreInfo(
      core: (map['core'] as num?)?.toInt() ?? 0,
      frequency: (map['frequency'] as num?)?.toInt() ?? 0,
      maxFrequency: (map['maxFrequency'] as num?)?.toInt() ?? 0,
      minFrequency: (map['minFrequency'] as num?)?.toInt() ?? 0,
      governor: map['governor'] as String? ?? 'unknown',
    );
  }
}

class ChartDataPoint {
  final String time;
  final double cpu;
  final double gpu;
  final int fps;

  ChartDataPoint({
    required this.time,
    this.cpu = 0,
    this.gpu = 0,
    this.fps = 0,
  });
}
