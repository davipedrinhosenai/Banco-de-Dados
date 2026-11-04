-- habilitando extensao para senhas
create extension if not exists pgcrypto;

-- criando tabelas
create table categorias (
    id_categoria serial primary key,
    nome varchar(50) not null unique,
    descricao text
);

create table colaboradores (
    id_colaborador serial primary key,
    nome varchar(100) not null,
    email varchar(100) not null unique,
    senha varchar(255) not null,
    ativo boolean not null default true,
    criado_em timestamp default current_timestamp
);

create table tarefas (
    id_tarefa serial primary key,
    titulo varchar(150) not null,
    descricao text,
    prazo_entrega date not null,
    status varchar(20) not null default 'Pendente' check (status in ('Pendente', 'Em Andamento', 'Concluída', 'Cancelada')),
    id_categoria int not null references categorias(id_categoria),
    id_colaborador int not null references colaboradores(id_colaborador),
    criado_em timestamp default current_timestamp
);

create table historico_tarefas (
    id_historico serial primary key,
    id_tarefa int not null,
    acao varchar(50) not null,
    descricao varchar(255),
    data_registro timestamp default current_timestamp
);

-- inserindo dados
insert into categorias (nome, descricao) values
('Desenvolvimento', 'Demandas ligadas a código, bugs e novas funcionalidades'),
('Infraestrutura', 'Manutenção de servidores, redes e banco de dados'),
('Design / UX', 'Criação de mockups, wireframes e identidade visual');

insert into colaboradores (nome, email, senha, ativo) values
('Carlos Silva', 'carlos.silva@empresa.com', crypt('Senha123*', gen_salt('bf')), true),
('Mariana Souza', 'mariana.souza@empresa.com', crypt('Mari@2024', gen_salt('bf')), true),
('Roberto Alves', 'roberto.alves@empresa.com', crypt('Admin#987', gen_salt('bf')), false);

insert into tarefas (titulo, descricao, prazo_entrega, status, id_categoria, id_colaborador) values
('Ajustar Query do Dashboard', 'Otimizar a consulta de relatórios mensais', current_date + interval '3 days', 'Em Andamento', 1, 1),
('Migração PostgreSQL', 'Atualizar a versão do servidor de banco de dados', current_date + interval '1 day', 'Pendente', 2, 2),
('Refatorar Telas de Login', 'Implementar novo layout acessível e responsivo', current_date + interval '7 days', 'Pendente', 3, 1);

-- funcao de autenticacao
create or replace function fn_autenticar_usuario(
    p_email varchar,
    p_senha varchar
)
returns table (
    autenticado boolean,
    mensagem text,
    id_colaborador int,
    nome varchar
) as $$
declare
    v_colaborador record;
begin
    select c.id_colaborador, c.nome, c.senha, c.ativo
    into v_colaborador
    from colaboradores c
    where c.email = p_email;

    if not found then
        return query select false, 'E-mail ou senha inválidos.'::text, null::int, null::varchar;
        return;
    end if;

    if not v_colaborador.ativo then
        return query select false, 'Usuário inativo no sistema.'::text, null::int, null::varchar;
        return;
    end if;

    if v_colaborador.senha = crypt(p_senha, v_colaborador.senha) then
        return query select true, 'Autenticação realizada com sucesso!'::text, v_colaborador.id_colaborador, v_colaborador.nome;
    else
        return query select false, 'E-mail ou senha inválidos.'::text, null::int, null::varchar;
    end if;
end;
$$ language plpgsql;

-- funcao de busca
create or replace function fn_buscar_colaboradores(
    p_termo varchar
)
returns table (
    id_colaborador int,
    nome varchar,
    email varchar,
    ativo boolean
) as $$
begin
    return query
    select 
        c.id_colaborador,
        c.nome,
        c.email,
        c.ativo
    from colaboradores c
    where c.nome ilike '%' || p_termo || '%'
       or c.email ilike '%' || p_termo || '%';
end;
$$ language plpgsql;

-- triggers
create or replace function fn_trg_validar_tarefa()
returns trigger as $$
declare
    v_ativo boolean;
begin
    select ativo into v_ativo
    from colaboradores
    where id_colaborador = new.id_colaborador;

    if v_ativo is not true then
        raise exception 'Não é possível atribuir a tarefa. O colaborador informado não existe ou está inativo.';
    end if;

    if new.criado_em is null then
        new.criado_em := current_timestamp;
    end if;

    return new;
end;
$$ language plpgsql;

create trigger trg_validar_tarefa
before insert on tarefas
for each row
execute function fn_trg_validar_tarefa();

create or replace function fn_trg_log_historico_tarefa()
returns trigger as $$
begin
    insert into historico_tarefas (id_tarefa, acao, descricao)
    values (new.id_tarefa, 'CRIAÇÃO', concat('Tarefa "', new.titulo, '" criada e vinculada ao colaborador ID ', new.id_colaborador));
    return new;
end;
$$ language plpgsql;

create trigger trg_log_historico_tarefa
after insert on tarefas
for each row
execute function fn_trg_log_historico_tarefa();

-- criando views
create or replace view vw_painel_principal as
select 
    c.nome as colaborador,
    t.titulo as tarefa,
    cat.nome as categoria,
    t.prazo_entrega,
    t.status
from tarefas t
inner join colaboradores c on t.id_colaborador = c.id_colaborador
inner join categorias cat on t.id_categoria = cat.id_categoria;

create or replace view vw_cronograma_prazos as
select 
    t.id_tarefa,
    t.titulo as tarefa,
    t.status,
    (t.prazo_entrega - current_date) as dias_restantes,
    t.prazo_entrega,
    c.nome as responsavel
from tarefas t
inner join colaboradores c on t.id_colaborador = c.id_colaborador
order by t.prazo_entrega asc;