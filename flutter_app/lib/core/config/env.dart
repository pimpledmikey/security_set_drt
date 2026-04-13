class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dev.bsys.mx/scriptcase/app/Gilneas',
  );

  static const deviceId = String.fromEnvironment(
    'DEVICE_ID',
    defaultValue: 'RUNWAY-TAB-01',
  );
}
