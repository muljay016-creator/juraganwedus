# JURAGAN — Panduan Penerapan (Supabase + Vercel)

Isi folder:
- index.html   : website publik (semua isinya diatur dari admin)
- admin.html   : dashboard admin (buka di /admin.html)
- config.js    : HANYA 2 isian: URL dan kunci anon Supabase
- schema.sql   : database inti, keamanan, fungsi stok  (JALANKAN PERTAMA)
- schema-2.sql : pengaturan, media, paket, testimoni, galeri, FAQ (JALANKAN KEDUA)
- schema-3.sql : kategori dinamis, keunggulan, langkah pesan, label & harga coret, banyak pengaturan (JALANKAN KETIGA)
- vercel.json  : pengaturan Vercel

## A. SUPABASE
1. Buka https://supabase.com > Sign up > "New project". Nama: juragan. Region: Singapore. Buat dan simpan password database. Tunggu 1-2 menit.
2. Menu "SQL Editor" > "New query". Salin seluruh isi schema.sql, tempel, klik "Run". Harus muncul "Success".
3. "New query" lagi. Salin seluruh isi schema-2.sql, tempel, "Run". Ulangi untuk schema-3.sql.
4. Menu "Authentication" > "Users" > "Add user" > "Create new user". Isi email dan password pemilik, centang "Auto Confirm User". Salin UUID user tersebut.
5. Di SQL Editor jalankan (ganti UUID-PEMILIK). WAJIB menulis 'owner', kalau tidak menu admin hanya tampil Ringkasan:
   insert into profiles(id,nama,role) values('UUID-PEMILIK','Pemilik','owner');
6. Menu "Project Settings" > "API". Salin "Project URL" dan kunci "anon public". Jangan pakai service_role.
7. Menu "Storage": pastikan ada bucket "produk" (publik). Dibuat otomatis oleh schema.sql.

## B. ISI config.js
Ganti SUPABASE_URL dan SUPABASE_ANON_KEY. Hanya itu yang diedit di kode.

## C. GITHUB
1. https://github.com > "New repository", nama juragan-web.
2. "uploading an existing file", unggah: index.html, admin.html, config.js, vercel.json. Klik "Commit changes".

## D. VERCEL (gratis)
1. https://vercel.com > Sign up dengan GitHub.
2. "Add New..." > "Project" > pilih juragan-web > "Import".
3. Framework Preset: Other. Kosongkan Build Command dan Output Directory. Klik "Deploy".
4. Alamat jadi: namaproject.vercel.app. Ganti nama di Project > Settings > Domains > Edit.
5. Supabase > Authentication > URL Configuration: isi "Site URL" dengan alamat Vercel Anda.

## E. ISI WEBSITE DARI ADMIN (tanpa ubah kode)
Buka https://ALAMAT-ANDA/admin.html, login sebagai pemilik.
1. Pengaturan: isi nomor WhatsApp, alamat, jam buka, peta, judul, warna, profil usaha, foto pemilik/kandang, tanggal Idul Adha, template pesan WhatsApp. Atur bagian mana yang tampil.
2. Produk: tambah kambing, simpan, lalu unggah beberapa foto dan video di panel "Foto & video produk".
3. Paket, Testimoni, Galeri, FAQ: tambah dari tab masing-masing. Bagian yang kosong otomatis tidak tampil di website.
4. Stok & Penjualan: ubah stok dan catat transaksi. Ringkasan menampilkan kartu stok dan grafik penjualan.

## F. TAMBAH ADMIN
Buat user di Authentication > Users, lalu SQL Editor (ganti UUID-ADMIN):
   insert into profiles(id,nama,role) values('UUID-ADMIN','Admin 1','admin');
   insert into permissions(user_id,module,can_view,can_create,can_edit,can_delete) values
   ('UUID-ADMIN','produk',true,true,true,false),('UUID-ADMIN','stok',true,false,true,false),
   ('UUID-ADMIN','laporan',true,false,false,false),('UUID-ADMIN','galeri',true,true,true,false),
   ('UUID-ADMIN','testimoni',true,true,true,false),('UUID-ADMIN','paket',true,true,true,false),
   ('UUID-ADMIN','faq',true,true,true,false);
Modul izin: produk, stok, laporan, paket, testimoni, galeri, faq, pengaturan.
Nonaktifkan: update profiles set active=false where id='UUID-ADMIN';

## G. UJI
1. Website tampil, produk muncul, klik kambing membuka foto dan video.
2. Tombol WhatsApp membuka nomor yang benar dengan pesan terisi.
3. Catat transaksi Berhasil: stok berkurang dan tercatat di Riwayat.

## Catatan
- Setiap file di GitHub berubah, Vercel otomatis memperbarui website.
- Supabase gratis: 1 GB penyimpanan file, 50 MB per file. Foto otomatis dikecilkan saat diunggah.
- Project Supabase gratis dijeda jika tidak aktif 7 hari. Buka sekali seminggu atau upgrade.
- Kunci anon boleh terlihat di website; keamanan dijaga aturan RLS di schema.
- Tanggal Idul Adha bawaan hanya perkiraan. Periksa penetapan resmi lalu ubah di Pengaturan.

## MASALAH UMUM
- Menu admin hanya "Ringkasan": akun Anda terdaftar sebagai admin, bukan pemilik. Jalankan di SQL Editor:
  update profiles set role='owner' where id='UUID-ANDA';
  (UUID Anda tampil di kotak peringatan pada halaman Ringkasan.)
- Muncul "Tabel belum ada": jalankan schema-2.sql dan schema-3.sql.
- Hitung mundur tidak tampil: isi tanggal di Admin > Pengaturan > Hitung mundur Idul Adha.
- Perubahan di admin belum terlihat di website: muat ulang halaman (Ctrl+F5).
