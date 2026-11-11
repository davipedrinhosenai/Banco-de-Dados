create table colaboradores (
    id serial primary key,
    nome varchar(100) not null,
    email varchar(100) unique not null,
    cpf varchar(14) unique not null,
    senha_hash varchar(255) not null,
    ativo boolean default true,
    data_cadastro timestamp default current_timestamp
);

create table categorias (
    id serial primary key,
    nome varchar(50) unique not null
);

create table projetos (
    id serial primary key,
    nome varchar(100) not null,
    descricao text,
    data_inicio date not null,
    data_fim date,
    constraint chk_datas_projeto check (
        data_fim is null or data_fim >= data_inicio
    )
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
    categoria_id int not null,
    projeto_id int not null,

    constraint fk_tarefa_colaborador
        foreign key (colaborador_id)
        references colaboradores(id),

    constraint fk_tarefa_categoria
        foreign key (categoria_id)
        references categorias(id),

    constraint fk_tarefa_projeto
        foreign key (projeto_id)
        references projetos(id),

    constraint chk_status_tarefa
        check (status in ('pendente', 'em andamento', 'concluida', 'cancelada')),

    constraint chk_datas_tarefa
        check (data_entrega >= data_agendamento)
);

create table historico_tarefas (
    id serial primary key,
    tarefa_id int not null,
    descricao text not null,
    data_registro timestamp default current_timestamp,

    constraint fk_historico_tarefa
        foreign key (tarefa_id)
        references tarefas(id)
);
