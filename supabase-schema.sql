-- بیمه‌یار: طرح اولیه پایگاه داده Supabase (PostgreSQL)
-- 1) این فایل را در Supabase > SQL Editor اجرا کنید.
-- 2) در Authentication یک کاربر مدیر ایجاد کنید.
-- 3) UUID کاربر مدیر را در دستور UPDATE/INSERT پایین جایگزین کنید.
-- نکته: قبل از انتشار عمومی، سیاست‌ها را با پروژه واقعی آزمایش کنید.

create table if not exists public.insurance_products (
  id text primary key,
  title text not null,
  category text not null,
  icon text not null default '🛡️',
  description text not null,
  official_url text not null,
  is_published boolean not null default true,
  sort_order integer not null default 100,
  updated_at timestamptz not null default now(),
  constraint official_url_https check (official_url ~ '^https://')
);

create table if not exists public.site_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.insurance_products enable row level security;
alter table public.site_admins enable row level security;

-- عموم فقط محصولات منتشرشده را می‌خوانند.
create policy "public can read published insurance products"
on public.insurance_products for select
to anon, authenticated
using (is_published = true);

-- مدیران می‌توانند همه محصولات را ببینند و تغییر دهند.
create policy "admins can read all insurance products"
on public.insurance_products for select
to authenticated
using (exists (select 1 from public.site_admins a where a.user_id = auth.uid()));

create policy "admins can insert insurance products"
on public.insurance_products for insert
to authenticated
with check (exists (select 1 from public.site_admins a where a.user_id = auth.uid()));

create policy "admins can update insurance products"
on public.insurance_products for update
to authenticated
using (exists (select 1 from public.site_admins a where a.user_id = auth.uid()))
with check (exists (select 1 from public.site_admins a where a.user_id = auth.uid()));

create policy "admins can delete insurance products"
on public.insurance_products for delete
to authenticated
using (exists (select 1 from public.site_admins a where a.user_id = auth.uid()));

-- پس از ایجاد کاربر مدیر، UUID او را جایگزین کنید:
-- insert into public.site_admins (user_id) values ('UUID-OF-AUTH-USER');

insert into public.insurance_products
(id,title,category,icon,description,official_url,is_published,sort_order)
values
('car-third','بیمه شخص ثالث خودرو','خودرو','🚘','برای بررسی شرایط و استعلام بیمه شخص ثالث خودرو از ارائه‌دهنده رسمی استفاده کنید.','https://www.azki.com/car-insurance',true,1),
('car-body','بیمه بدنه خودرو','خودرو','🚗','برای بررسی پوشش‌ها و استعلام قیمت بیمه بدنه، مشخصات خودرو را در صفحه رسمی وارد کنید.','https://www.azki.com/car-insurance',true,2),
('motor','بیمه موتورسیکلت','موتور','🏍️','شرایط بیمه موتور و قیمت نهایی پس از استعلام در سایت ارائه‌دهنده مشخص می‌شود.','https://www.azki.com/car-insurance',true,3),
('home','بیمه آتش‌سوزی و ساختمان','ساختمان','🏠','پوشش‌های ساختمان، آتش‌سوزی و زلزله را در صفحه رسمی بررسی کنید.','https://www.azki.com/',true,4),
('life','بیمه عمر','عمر و درمان','💚','شرایط، تعهدات و جزئیات بیمه عمر را پیش از خرید از ارائه‌دهنده بررسی کنید.','https://www.azki.com/',true,5),
('health','بیمه درمان تکمیلی','عمر و درمان','🩺','نوع پوشش و شرایط قرارداد می‌تواند متفاوت باشد؛ جزئیات را در سایت ارائه‌دهنده بررسی کنید.','https://www.azki.com/',true,6),
('travel','بیمه مسافرتی','مسافرتی','✈️','پوشش‌ها را با توجه به مقصد و مدت سفر در صفحه رسمی بررسی کنید.','https://www.azki.com/',true,7),
('liability','بیمه مسئولیت','سایر','🛡️','نوع مسئولیت و حدود تعهدات باید متناسب با فعالیت موردنظر بررسی شود.','https://www.azki.com/',true,8)
on conflict (id) do nothing;
