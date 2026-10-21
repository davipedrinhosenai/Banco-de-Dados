create table contas (
    id serial primary key,
    cliente varchar(100) not null,
    saldo numeric(10, 2) not null default 0.00
);

create table movimentacoes (
    id serial primary key,
    conta_id int references contas(id),
    tipo varchar(1) check (tipo in ('c', 'd')),
    valor numeric(10, 2) not null,
    data_movimentacao timestamp default current_timestamp
);

create or replace function fn_atualiza_saldo_conta()
returns trigger as $$
begin
    if new.tipo = 'c' then
        update contas set saldo = saldo + new.valor where id = new.conta_id;
    elsif new.tipo = 'd' then
        update contas set saldo = saldo - new.valor where id = new.conta_id;
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_atualiza_saldo
after insert on movimentacoes
for each row
execute function fn_atualiza_saldo_conta();