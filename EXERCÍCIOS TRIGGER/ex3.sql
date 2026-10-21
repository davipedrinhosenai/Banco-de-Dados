create table funcionarios (
    id serial primary key,
    nome varchar(100) not null,
    cargo varchar(50) not null,
    salario numeric(10, 2) not null
);

create table historico_carreira (
    id serial primary key,
    funcionario_id int not null,
    cargo_antigo varchar(50),
    cargo_novo varchar(50),
    salario_antigo numeric(10, 2),
    salario_novo numeric(10, 2),
    data_alteracao timestamp default current_timestamp
);

create or replace function fn_log_alteracao_carreira()
returns trigger as $$
begin
    if old.cargo is distinct from new.cargo or old.salario is distinct from new.salario then
        insert into historico_carreira (funcionario_id, cargo_antigo, cargo_novo, salario_antigo, salario_novo)
        values (old.id, old.cargo, new.cargo, old.salario, new.salario);
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_log_carreira
after update on funcionarios
for each row
execute function fn_log_alteracao_carreira();