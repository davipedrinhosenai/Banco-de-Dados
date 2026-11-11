
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
    data_agendamento,
    data_entrega,
    status,
    colaborador_id,
    projeto_id
)
values
('criar tela de login', 'desenvolver a tela de autenticacao', '2026-11-11', '2026-11-15', 'pendente', 1, 1),

('documentar funcionalidades', 'documentar as funcionalidades do sistema', '2026-11-11', '2026-11-20', 'em andamento', 2, 1),

('planejar interface', 'definir o planejamento visual do aplicativo', '2026-11-12', '2026-11-25', 'pendente', 1, 3);


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
