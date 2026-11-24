-- JURAGAN schema-3: jalankan SETELAH schema.sql dan schema-2.sql
-- Menambah: kategori dinamis, keunggulan & langkah pesan, label/harga coret/unggulan produk, dan banyak pengaturan.
alter table products drop constraint if exists products_category_check;
alter table products add column if not exists badge text;
alter table products add column if not exists featured bool default false;
alter table products add column if not exists price_old bigint;
create table categories(id uuid primary key default gen_random_uuid(), name text unique not null, icon text, description text, sort int default 0, active bool default true);
create table highlights(id uuid primary key default gen_random_uuid(), kind text not null check (kind in ('why','step')), icon text, title text not null, body text, sort int default 0, active bool default true);
alter table categories enable row level security; alter table highlights enable row level security;
do $$ declare r record; begin
 for r in select * from (values ('categories','pengaturan','active'),('highlights','pengaturan','active')) as v(t,m,c) loop
  execute format('create policy "baca %1$s" on %1$s for select using (%3$s or has_perm(%2$L,''view''))',r.t,r.m,r.c);
  execute format('create policy "tambah %1$s" on %1$s for insert with check (has_perm(%2$L,''create'') or has_perm(%2$L,''edit''))',r.t,r.m);
  execute format('create policy "ubah %1$s" on %1$s for update using (has_perm(%2$L,''edit''))',r.t,r.m);
  execute format('create policy "hapus %1$s" on %1$s for delete using (has_perm(%2$L,''edit''))',r.t,r.m);
 end loop; end $$;
insert into categories(name,icon,description,sort) values ('Umum','🐐','Konsumsi, kuliner, reseller',1),('Kurban','🌙','Sehat dan memenuhi syarat',2),('Aqiqah','🎉','Untuk buah hati tercinta',3);
insert into highlights(kind,icon,title,body,sort) values
('why','📋','Informasi transparan','Kode, bobot, umur, dan harga setiap kambing tertera jelas.',1),
('why','📸','Sesuai foto aslinya','Yang Anda lihat di katalog sesuai kondisi di kandang.',2),
('why','🚚','Siap antar','Pengiriman Cirebon dan sekitarnya. Luar kota dikonfirmasi via WhatsApp.',3),
('why','💬','Pesan lewat WhatsApp','Tanpa daftar akun. Tanya, nego, dan sepakati langsung.',4),
('step','','Pilih kambing','Telusuri katalog atau paket sesuai anggaran.',1),
('step','','Klik WhatsApp','Pesan berisi nama, kode, dan harga terisi otomatis.',2),
('step','','Sepakati detail','Konfirmasi stok, lokasi antar, dan pembayaran.',3),
('step','','Kambing diantar','Diantar sesuai kesepakatan ke alamat Anda.',4);
insert into settings(key,value) values
('brand_icon','🐐'),('logo_url',''),('tagline','Pilihan Kambing Termurah, Siap Antar'),('meta_description','Jual kambing umum, kurban, dan aqiqah. Harga jelas, siap antar, pesan via WhatsApp.'),
('wa_label','WhatsApp'),('wa_greeting','Halo, saya ingin bertanya tentang kambing.'),('wa_package_template','Halo, saya ingin konsultasi {paket}'),
('instagram',''),('tiktok',''),('facebook',''),('youtube',''),
('announce_on','0'),('announce_text',''),('announce_link',''),
('hero_eyebrow','Cirebon dan sekitarnya'),('hero_btn1','Lihat Katalog →'),('hero_btn2','Hubungi WhatsApp'),('hero_image',''),('hero_card','1'),('hero_card_3_title','Siap antar'),('hero_card_3_sub','Area Cirebon'),
('floating_wa','1'),
('cat_title','Kategori Kambing'),('cat_sub','Pilih sesuai kebutuhan dan anggaran Anda.'),
('calculator_title','Kalkulator Anggaran'),('calculator_sub','Masukkan anggaran Anda, kami tampilkan kambing yang tersedia dan cocok.'),
('catalog_title','Katalog Kambing'),('catalog_sub','Klik kambing untuk melihat foto dan video lengkap.'),
('packages_title','Paket Layanan'),('packages_sub','Dari memilih kambing sampai penyembelihan, kami bantu semuanya.'),
('gallery_title','Galeri'),('gallery_sub','Kandang, pengiriman, dan layanan kurban atau aqiqah.'),
('testimonials_title','Testimoni'),('testimonials_sub','Pengalaman pelanggan kami.'),
('steps_title','Cara Pesan'),('steps_sub','Empat langkah mudah.'),
('why_title','Kenapa Pilih Kami'),('why_sub',''),
('faq_title','Pertanyaan Umum'),
('cta_title','Siap memilih kambing terbaik?'),('cta_sub','Hubungi kami sekarang. Konsultasi gratis, tanpa kewajiban membeli.'),('cta_btn','Chat WhatsApp Sekarang'),
('show_cat','1'),('show_catalog','1'),('show_steps','1'),('show_why','1'),('show_cta','1'),
('order_cat','10'),('order_calculator','20'),('order_catalog','30'),('order_packages','40'),('order_about','50'),('order_gallery','60'),('order_testimonials','70'),('order_steps','80'),('order_why','90'),('order_faq','100'),('order_cta','110'),
('low_stock','1')
on conflict do nothing;
