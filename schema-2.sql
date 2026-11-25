-- JURAGAN schema-2: jalankan SETELAH schema.sql (SQL Editor > Run)
-- Menambah: pengaturan, media produk, paket, testimoni, galeri, FAQ. Semua dikelola dari admin.
create table settings(key text primary key, value text, updated_at timestamptz default now());
create table product_media(id uuid primary key default gen_random_uuid(), product_id uuid references products on delete cascade, media_type text not null check (media_type in ('image','video')), url text not null, sort int default 0, created_at timestamptz default now());
create table packages(id uuid primary key default gen_random_uuid(), package_type text, name text not null, price_text text, features text, featured bool default false, active bool default true, sort int default 0);
create table testimonials(id uuid primary key default gen_random_uuid(), customer_name text not null, content text not null, photo_url text, published bool default false, created_at timestamptz default now());
create table gallery(id uuid primary key default gen_random_uuid(), title text, category text, media_type text default 'image', url text not null, active bool default true, sort int default 0);
create table faqs(id uuid primary key default gen_random_uuid(), question text not null, answer text not null, active bool default true, sort int default 0);
alter table settings enable row level security; alter table product_media enable row level security; alter table packages enable row level security; alter table testimonials enable row level security; alter table gallery enable row level security; alter table faqs enable row level security;
create policy "baca pengaturan" on settings for select using (true);
create policy "tulis pengaturan" on settings for all using (has_perm('pengaturan','edit')) with check (has_perm('pengaturan','edit'));
do $$ declare r record; begin
 for r in select * from (values ('product_media','produk','true'),('packages','paket','active'),('testimonials','testimoni','published'),('gallery','galeri','active'),('faqs','faq','active')) as v(t,m,c) loop
  execute format('create policy "baca %1$s" on %1$s for select using (%3$s or has_perm(%2$L,''view''))',r.t,r.m,r.c);
  execute format('create policy "tambah %1$s" on %1$s for insert with check (has_perm(%2$L,''create''))',r.t,r.m);
  execute format('create policy "ubah %1$s" on %1$s for update using (has_perm(%2$L,''edit''))',r.t,r.m);
  execute format('create policy "hapus %1$s" on %1$s for delete using (has_perm(%2$L,''delete''))',r.t,r.m);
 end loop; end $$;
create policy "upload konten" on storage.objects for insert to authenticated with check (bucket_id='produk' and (has_perm('galeri','create') or has_perm('testimoni','create') or has_perm('paket','create') or has_perm('pengaturan','edit')));
insert into settings(key,value) values
('brand_name','JURAGAN'),
('hero_title','Pilihan Kambing *Termurah*, Siap Antar'),
('hero_sub','Kambing sehat untuk konsumsi, kurban, dan aqiqah. Harga, bobot, dan umur tertera jelas. Pesan langsung lewat WhatsApp.'),
('wa',''),('address',''),('hours',''),('maps_link',''),('maps_embed',''),('footer_note',''),
('color_primary','#164B35'),('color_accent','#D9A441'),
('wa_template',E'Halo Juragan, saya tertarik dengan produk kambing berikut:\n\nNama: {nama}\nKode: {kode}\nJenis: {jenis}\nBobot: {bobot}\nHarga: {harga}\n\nApakah produk ini masih tersedia?'),
('about_title','Tentang Kami'),('about_text',''),('owner_photo',''),('farm_photo',''),
('countdown_label','Menuju Idul Adha'),('countdown_date','2027-05-17'),
('show_countdown','1'),('show_calculator','1'),('show_packages','1'),('show_about','1'),('show_gallery','1'),('show_testimonials','1'),('show_faq','1')
on conflict do nothing;
-- Catatan: tanggal Idul Adha di atas perkiraan. Periksa penetapan resmi pemerintah lalu ubah di Admin > Pengaturan.
