NOTE!!!: 
- Design tampilan yang konsisten disemua screen sesuai dengan pengalamanmu sebagai mobile/web frontend & UI UX expert berpengalaman selama 20tahun.
- Jika Anda membuat Widget, letakkan codenya di folder /components dari root main module.
- terapkan modularisasi dengan memisahkan code widget/tampilan dengan code fungsi, dan code data (cth: data user, data daftar dokter). lalu, Jika ada fungsi yang ingin Anda buat, letakkan di folder /services (buat kalau tidak ada) dari root main module.
- Jika ada screen baru, buat codenya di folder /lib/screens
- Gunakan perintah flutter add {nama package yang ingin dinstall} untuk menambahkan dependensi.
Untuk root main module saya bakalan berikan/menandainya di chat.
- Jangan gunakan properti color withOpacity! gunakan withValues
- Don't use 'BuildContext's across async gaps.
Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check.
- 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss.
Try replacing the use of the deprecated member with the replacement.
- Use 'const' with the constructor to improve performance.
Try adding the 'const' keyword to the constructor invocation.
- Don't use 'BuildContext's across async gaps.
Try rewriting the code to not use the 'BuildContext', or guard the use with a 'mounted' check.
- 'value' is deprecated and shouldn't be used. Use initialValue instead. This will set the initial value for the form field. This feature was deprecated after v3.33.0-1.0.pre.
Try replacing the use of the deprecated member with the replacement.
- Unnecessary 'const' keyword.
Try removing the keyword.
- Use a 'SizedBox' to add whitespace to a layout.
Try using a 'SizedBox' rather than a 'Container'.
- Run 'flutter analyze' after u done all ur job to ensure no error from your code, and then fix that!