create table estoque(
	id serial primary key,
	nome_item varchar(100) not null,
	quantidade int not null default 0
);

create or replace function fn_valida_estoque_minimo()
returns trigger as $$
begin
    if new.quantidade < 0 then
        raise exception 'operação cancelada! o item "%" não pode ter estoque negativo (tentativa: % unidade(s)).', 
            new.nome_item, new.quantidade;
    end if;
    return new;
end;
$$ language plpgsql;	

create trigger trg_valida_estoque
before insert or update on estoque
for each row
execute function fn_valida_estoque_minimo();