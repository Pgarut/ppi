Uncaught SyntaxError: '' string literal contains an unescaped line break ppi-bo8.pages.dev:160:26
Injecting <script> tag. Using callback.

Project Flutter web (ppi_frontend) dideploy ke Cloudflare Pages 
sebagai ppi-bo8.pages.dev. Halaman stuck di splash screen 
"Memuat aplikasi..." dan tidak selesai load.

Error dari Console browser:
Uncaught SyntaxError: '' string literal contains an unescaped line break
at ppi-bo8.pages.dev:160:26

Cari file yang menghasilkan baris 160 tersebut - kemungkinan di 
web/index.html atau di build/web/index.html. Tunjukkan isi baris 
itu dan sekitarnya, jelaskan penyebabnya, jangan dulu di perbaiki atau push dan deploy