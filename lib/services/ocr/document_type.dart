enum DocumentType {
  drivingLicense('Driving License'),
  passport('Passport'),
  vehicleRc('Vehicle RC'),
  insurancePolicy('Insurance Policy'),
  panCard('PAN Card'),
  aadhaarCard('Aadhaar Card'),
  unknown('Unknown');

  const DocumentType(this.label);

  final String label;
}
