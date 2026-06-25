/// Uygulama genelinde kullanılan ortak form doğrulama (validation) yardımcıları.
///
/// Tüm metotlar `TextFormField.validator` imzasına uygundur:
/// geçerliyse `null`, geçersizse Türkçe hata mesajı döner.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// E-posta: zorunlu + makul format kontrolü.
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'E-posta zorunludur';
    if (!_emailRegex.hasMatch(v)) return 'Geçerli bir e-posta girin';
    return null;
  }

  /// Telefon: zorunlu + 10-11 hane (Türk cep formatı, baştaki 0 opsiyonel).
  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Telefon numarası zorunludur';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 11) {
      return 'Geçerli bir telefon numarası girin (10-11 hane)';
    }
    return null;
  }

  /// E-posta (opsiyonel): boşsa geçerli, doluysa format kontrolü.
  static String? emailOptional(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return email(value);
  }

  /// Telefon (opsiyonel): boşsa geçerli, doluysa format kontrolü.
  static String? phoneOptional(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return phone(value);
  }

  /// Zorunlu metin alanı. [alan] hata mesajında kullanılır.
  static String? required(String? value, {String alan = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) return '$alan zorunludur';
    return null;
  }

  /// Şifre: zorunlu + en az 6 karakter.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty || v.length < 6) return 'Şifre en az 6 karakter olmalı';
    return null;
  }
}
