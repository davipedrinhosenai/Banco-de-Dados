
-- criacao das tabelas

create table colaboradores (
    id serial primary key,
    nome varchar(100) not null,
    email varchar(100) unique not null,
    cpf varchar(14) unique not null,
    senha_hash varchar(255) not null,
    ativo boolean default true,
    data_cadastro timestamp default current_timestamp
);

create table projetos (
    id serial primary key,
    nome varchar(100) not null,
    descricao text,
    data_inicio date not null,
    data_fim date,
    check (data_fim is null or data_fim >= data_inicio)
);

create table tarefas (
    id serial primary key,
    titulo varchar(150) not null,
    descricao text,
    categoria varchar(50) not null,
    data_criacao timestamp default current_timestamp,
    data_agendamento date not null,
    data_entrega date not null,
    status varchar(30) default 'pendente',
    colaborador_id int not null,
    projeto_id int not null,

    foreign key (colaborador_id)
        references colaboradores(id),

    foreign key (projeto_id)
        references projetos(id),

    check (status in ('pendente', 'em andamento', 'concluida', 'cancelada')),

    check (data_entrega >= data_agendamento)
);

create table historico_tarefas (
    id serial primary key,
    tarefa_id int not null,
    descricao text not null,
    data_registro timestamp default current_timestamp,

    foreign key (tarefa_id)
        references tarefas(id)
);


-- insercao dos dados

insert into colaboradores (nome, email, cpf, senha_hash, ativo)
values
('joao silva', 'joao@email.com', '123.456.789-00', 'hash123', true),
('maria souza', 'maria@email.com', '987.654.321-00', 'hash456', true),
('pedro santos', 'pedro@email.com', '111.222.333-44', 'hash789', false);


insert into projetos (nome, descricao, data_inicio, data_fim)
values
('sistema de vendas', 'desenvolvimento de um sistema de vendas', '2026-11-01', '2026-12-15'),
('site institucional', 'criacao de um site para a empresa', '2026-11-05', '2026-12-20'),
('aplicativo mobile', 'desenvolvimento de aplicativo para dispositivos moveis', '2026-11-10', '2027-01-30');


insert into tarefas (
    titulo,
    descricao,
    categoria,
    data_agendamento,
    data_entrega,
    status,
    colaborador_id,
    projeto_id
)
values
('criar tela de login', 'desenvolver a tela de autenticacao', 'desenvolvimento', '2026-11-11', '2026-11-15', 'pendente', 1, 1),

('documentar funcionalidades', 'documentar as funcionalidades do sistema', 'documentacao', '2026-11-11', '2026-11-20', 'em andamento', 2, 1),

('planejar interface', 'definir o planejamento visual do aplicativo', 'planejamento', '2026-11-12', '2026-11-25', 'pendente', 1, 3);


insert into historico_tarefas (tarefa_id, descricao)
values
(1, 'tarefa cadastrada no sistema'),
(2, 'tarefa cadastrada e iniciada'),
(3, 'tarefa cadastrada no sistema');


-- consultas para conferir os registros

select * from colaboradores;
select * from projetos;
select * from tarefas;
select * from historico_tarefas;


-- funcao de autenticacao

create or replace function fn_autenticar_usuario(
    p_email varchar,
    p_senha varchar
)
returns text
language plpgsql
as $$
declare
    usuario_encontrado colaboradores%rowtype;
begin
    select *
    into usuario_encontrado
    from colaboradores
    where email = p_email;

    if not found then
        return 'email ou senha invalidos';
    end if;

    if usuario_encontrado.senha_hash <> p_senha then
        return 'email ou senha invalidos';
    end if;

    if usuario_encontrado.ativo = false then
        return 'colaborador inativo';
    end if;

    return 'autenticacao realizada com sucesso';
end;
$$;


-- funcao de busca de colaboradores

create or replace function fn_buscar_colaboradores(
    p_termo varchar
)
returns table (
    id int,
    nome varchar,
    email varchar,
    ativo boolean
)
language plpgsql
as $$
begin
    return query
    select
        c.id,
        c.nome,
        c.email,
        c.ativo
    from colaboradores c
    where c.nome ilike '%' || p_termo || '%'
       or c.email ilike '%' || p_termo || '%';
end;
$$;


-- funcao para validar tarefas

create or replace function fn_validar_tarefa()
returns trigger
language plpgsql
as $$
declare
    colaborador_ativo boolean;
begin
    -- verifica se o colaborador esta ativo
    select ativo
    into colaborador_ativo
    from colaboradores
    where id = new.colaborador_id;

    if colaborador_ativo is distinct from true then
        raise exception 'colaborador inexistente ou inativo';
    end if;

    -- registra a data de criacao
    new.data_criacao := current_timestamp;

    return new;
end;
$$;


-- funcao para registrar o historico

create or replace function fn_registrar_historico()
returns trigger
language plpgsql
as $$
begin
    insert into historico_tarefas (tarefa_id, descricao)
    values (new.id, 'tarefa cadastrada no sistema');

    return new;
end;
$$;


-- views

-- view do painel principal

create or replace view vw_painel_principal as
select
    c.nome as colaborador,
    t.titulo as tarefa,
    t.categoria,
    t.data_entrega,
    t.status
from tarefas t
inner join colaboradores c
    on t.colaborador_id = c.id;


-- view do cronograma de prazos

create or replace view vw_cronograma_prazos as
select
    t.id,
    t.titulo,
    c.nome as colaborador,
    p.nome as projeto,
    t.categoria,
    t.status,
    t.data_entrega,
    (t.data_entrega - current_date) as dias_restantes
from tarefas t
inner join colaboradores c
    on t.colaborador_id = c.id
inner join projetos p
    on t.projeto_id = p.id
order by t.data_entrega asc;


-- triggers

-- trigger para validar tarefas

create trigger trg_validar_tarefa
before insert on tarefas
for each row
execute function fn_validar_tarefa();


-- trigger para registrar o historico

create trigger trg_registrar_historico
after insert on tarefas
for each row
execute function fn_registrar_historico();


-- testes das funcoes e views

select fn_autenticar_usuario('joao@email.com', 'hash123');

select * from fn_buscar_colaboradores('joao');

select * from vw_painel_principal;

select * from vw_cronograma_prazos;

select * from historico_tarefas;
