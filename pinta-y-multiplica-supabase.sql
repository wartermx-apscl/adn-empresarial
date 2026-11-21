-- Pinta y Multiplica: guarda el avance en la nube para verlo desde cualquier aparato.
-- Cómo usarlo: en Supabase abre "SQL Editor", pega todo este archivo y dale "Run".
-- Es seguro correrlo más de una vez.
--
-- Seguridad: la tabla no se puede leer ni escribir directamente con la llave pública.
-- Solo se usan las dos funciones de abajo, y cada una pide el código familiar
-- (PINTA-XXXX-XXXX), que funciona como contraseña del avance de cada niña.

create table if not exists public.pinta_avance (
  codigo      text primary key,
  nombre      text,
  datos       jsonb not null,
  actualizado timestamptz not null default now()
);

alter table public.pinta_avance enable row level security;
revoke all on public.pinta_avance from anon, authenticated;

-- Guarda (o reemplaza) el avance de un código.
create or replace function public.pinta_guardar(p_codigo text, p_nombre text, p_datos jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_codigo is null or p_codigo !~ '^PINTA-[A-Z0-9]{4}-[A-Z0-9]{4}$' then
    raise exception 'codigo invalido';
  end if;
  if p_datos is null or pg_column_size(p_datos) > 300000 then
    raise exception 'datos invalidos';
  end if;
  insert into public.pinta_avance (codigo, nombre, datos, actualizado)
  values (p_codigo, left(coalesce(p_nombre, ''), 40), p_datos, now())
  on conflict (codigo) do update
    set nombre = excluded.nombre, datos = excluded.datos, actualizado = now();
end;
$$;

-- Lee el avance de un código (regresa null si no existe).
create or replace function public.pinta_leer(p_codigo text)
returns json
language sql
security definer
set search_path = public
as $$
  select json_build_object('nombre', nombre, 'datos', datos, 'actualizado', actualizado)
  from public.pinta_avance
  where codigo = upper(trim(p_codigo));
$$;

revoke all on function public.pinta_guardar(text, text, jsonb) from public;
revoke all on function public.pinta_leer(text) from public;
grant execute on function public.pinta_guardar(text, text, jsonb) to anon, authenticated;
grant execute on function public.pinta_leer(text) to anon, authenticated;
