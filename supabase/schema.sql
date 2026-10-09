create extension if not exists pgcrypto;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,email text,role text not null default 'customer' check(role in ('customer','admin')),created_at timestamptz not null default now());
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path='' as $$ begin insert into public.profiles(id,email,role) values(new.id,new.email,'customer') on conflict(id) do update set email=excluded.email; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- Security-definer helper avoids recursive RLS checks on profiles.
create or replace function public.is_current_user_admin() returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='admin');
$$;
revoke all on function public.is_current_user_admin() from public;
grant execute on function public.is_current_user_admin() to authenticated;

create table if not exists public.subscription_orders(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,plan_days integer not null check(plan_days in (7,14,30)),amount_usd numeric(8,2) not null check(amount_usd>0),transaction_reference text not null check(length(transaction_reference) between 4 and 200),sender_name text,status text not null default 'pending' check(status in ('pending','active','rejected','expired')),created_at timestamptz not null default now(),reviewed_at timestamptz,expires_at timestamptz);
alter table public.profiles enable row level security;
alter table public.subscription_orders enable row level security;
drop policy if exists "profile own or admin" on public.profiles;
create policy "profile own or admin" on public.profiles for select to authenticated using(id=(select auth.uid()) or public.is_current_user_admin());
drop policy if exists "orders own or admin" on public.subscription_orders;
create policy "orders own or admin" on public.subscription_orders for select to authenticated using(user_id=(select auth.uid()) or public.is_current_user_admin());
drop policy if exists "create own pending order" on public.subscription_orders;
create policy "create own pending order" on public.subscription_orders for insert to authenticated with check(user_id=(select auth.uid()) and status='pending' and expires_at is null);
revoke update,delete on public.subscription_orders from anon,authenticated;
grant select,insert on public.subscription_orders to authenticated;
grant select on public.profiles to authenticated;

create or replace function public.admin_review_subscription(p_order_id uuid,p_action text) returns void language plpgsql security definer set search_path='' as $$ declare o public.subscription_orders%rowtype; begin
if not public.is_current_user_admin() then raise exception 'Admin access required'; end if;
if p_action not in ('approve','reject') then raise exception 'Invalid action'; end if;
select * into o from public.subscription_orders where id=p_order_id for update;
if not found then raise exception 'Order not found'; end if;
if o.status<>'pending' then raise exception 'Order is not pending'; end if;
if p_action='approve' then update public.subscription_orders set status='active',reviewed_at=now(),expires_at=now()+make_interval(days=>o.plan_days) where id=p_order_id;
else update public.subscription_orders set status='rejected',reviewed_at=now() where id=p_order_id; end if; end; $$;
revoke all on function public.admin_review_subscription(uuid,text) from public;
grant execute on function public.admin_review_subscription(uuid,text) to authenticated;
