create table clientes (
    id serial primary key,
    nome varchar(100) not null,
    email varchar(100) not null,
    ativo boolean default true
);

create table clientes_deletados_log (
    id serial primary key,
    cliente_id int,
    nome varchar(100),
    email varchar(100),
    data_remocao timestamp default current_timestamp
);

create or replace function fn_soft_delete_cliente()
returns trigger as $$
begin
    insert into clientes_deletados_log (cliente_id, nome, email)
    values (old.id, old.nome, old.email);

    update clientes set ativo = false where id = old.id;

    return null;
end;
$$ language plpgsql;

create trigger trg_soft_delete_cliente
before delete on clientes
for each row
execute function fn_soft_delete_cliente();