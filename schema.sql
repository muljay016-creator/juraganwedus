-- JURAGAN: jalankan seluruh isi file ini di Supabase > SQL Editor
create table profiles(id uuid primary key references auth.users on delete cascade, nama text, role text not null default 'admin' check (role in ('owner','admin')), active boolean not null default true, created_at timestamptz default now());
create table permissions(id bigint generated always as identity primary key, user_id uuid references profiles on delete cascade, module text not null, can_view bool default false, can_create bool default false, can_edit bool default false, can_delete bool default false, unique(user_id,module));
create table products(id uuid primary key default gen_random_uuid(), code text unique not null, category text not null check (category in ('Umum','Kurban','Aqiqah')), name text not null, breed text, gender text check (gender in ('Jantan','Betina')), weight_min numeric, weight_max numeric, age text, price bigint not null check (price>=0), stock int not null default 0 check (stock>=0), description text, location text, image_url text, video_url text, status text not null default 'aktif' check (status in ('aktif','nonaktif')), created_at timestamptz default now(), updated_at timestamptz default now());
create table stock_history(id uuid primary key default gen_random_uuid(), product_id uuid references products on delete cascade, previous_stock int, change_amount int, current_stock int, reason text, created_by uuid, created_at timestamptz default now());
create table sales(id uuid primary key default gen_random_uuid(), customer_name text, customer_phone text, product_id uuid references products, quantity int not null check (quantity>0), total_price bigint, status text not null default 'Berhasil' check (status in ('Dipesan','Berhasil','Batal')), notes text, sale_date timestamptz default now(), created_by uuid);

-- Fungsi izin (dicek di server, bukan hanya menyembunyikan tombol)
create function is_owner() returns bool language sql security definer stable set search_path=public as $$ select exists(select 1 from profiles where id=auth.uid() and role='owner' and active) $$;
create function has_perm(m text,a text) returns bool language sql security definer stable set search_path=public as $$
 select is_owner() or exists(select 1 from profiles pr join permissions pe on pe.user_id=pr.id where pr.id=auth.uid() and pr.active and pe.module=m and case a when 'view' then pe.can_view when 'create' then pe.can_create when 'edit' then pe.can_edit when 'delete' then pe.can_delete else false end) $$;

-- Riwayat stok otomatis setiap stok berubah
create function log_stock() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.stock<>old.stock then
  insert into stock_history(product_id,previous_stock,change_amount,current_stock,reason,created_by) values(new.id,old.stock,new.stock-old.stock,new.stock,coalesce(nullif(current_setting('app.reason',true),''),'Perubahan manual'),auth.uid());
 end if; new.updated_at=now(); return new; end $$;
create trigger products_log before update on products for each row execute function log_stock();

-- Ubah stok aman (atomik, tidak bisa negatif)
create function adjust_stock(pid uuid,delta int,reason text) returns void language plpgsql security definer set search_path=public as $$
begin
 if not has_perm('stok','edit') then raise exception 'Anda tidak punya izin'; end if;
 perform set_config('app.reason',coalesce(reason,'Penyesuaian'),true);
 update products set stock=stock+delta where id=pid;
end $$;

-- Catat transaksi: stok berkurang hanya jika status Berhasil
create function record_sale(pid uuid,qty int,cname text,cphone text,total bigint,st text,nt text) returns uuid language plpgsql security definer set search_path=public as $$
declare sid uuid;
begin
 if not has_perm('stok','edit') then raise exception 'Anda tidak punya izin'; end if;
 if st='Berhasil' then perform set_config('app.reason','Penjualan '||coalesce(cname,''),true); update products set stock=stock-qty where id=pid; end if;
 insert into sales(customer_name,customer_phone,product_id,quantity,total_price,status,notes,created_by) values(cname,cphone,pid,qty,total,st,nt,auth.uid()) returning id into sid;
 return sid;
end $$;

-- Batalkan transaksi: stok dikembalikan
create function cancel_sale(sid uuid) returns void language plpgsql security definer set search_path=public as $$
declare s sales;
begin
 if not has_perm('stok','edit') then raise exception 'Anda tidak punya izin'; end if;
 select * into s from sales where id=sid;
 if s.status='Berhasil' then perform set_config('app.reason','Pembatalan transaksi',true); update products set stock=stock+s.quantity where id=s.product_id; end if;
 update sales set status='Batal' where id=sid;
end $$;

-- RLS
alter table profiles enable row level security; alter table permissions enable row level security; alter table products enable row level security; alter table stock_history enable row level security; alter table sales enable row level security;
create policy "profil sendiri/owner" on profiles for select using (id=auth.uid() or is_owner());
create policy "owner kelola profil" on profiles for all using (is_owner()) with check (is_owner());
create policy "izin sendiri/owner" on permissions for select using (user_id=auth.uid() or is_owner());
create policy "owner kelola izin" on permissions for all using (is_owner()) with check (is_owner());
create policy "publik lihat produk aktif" on products for select using (status='aktif' or has_perm('produk','view'));
create policy "tambah produk" on products for insert with check (has_perm('produk','create'));
create policy "ubah produk" on products for update using (has_perm('produk','edit'));
create policy "hapus produk" on products for delete using (has_perm('produk','delete'));
create policy "lihat riwayat stok" on stock_history for select using (has_perm('stok','view'));
create policy "lihat penjualan" on sales for select using (has_perm('laporan','view'));

-- Storage foto/video
insert into storage.buckets(id,name,public) values('produk','produk',true) on conflict do nothing;
create policy "upload media" on storage.objects for insert to authenticated with check (bucket_id='produk' and has_perm('produk','create'));

-- SETELAH membuat akun pemilik di Authentication > Users, jalankan (ganti UUID):
-- insert into profiles(id,nama,role) values('UUID-PEMILIK','Pemilik','owner');
-- Contoh izin admin:
-- insert into profiles(id,nama,role) values('UUID-ADMIN','Admin 1','admin');
-- insert into permissions(user_id,module,can_view,can_create,can_edit) values('UUID-ADMIN','produk',true,true,true),('UUID-ADMIN','stok',true,false,true),('UUID-ADMIN','laporan',true,false,false);
