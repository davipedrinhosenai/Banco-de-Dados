create table usuarios (
    id_usuario serial primary key,
    login varchar(50) not null unique,
    senha varchar(255) not null
);

create table turnos (
    id_turno serial primary key,
    nome_turno varchar(20) not null
);

create table maquinas (
    id_maquina serial primary key,
    nome_maquina varchar(100) not null,
    status varchar(20) not null default 'disponivel'
);

create table falhas (
    id_falha serial primary key,
    id_maquina integer references maquinas(id_maquina),
    id_usuario integer references usuarios(id_usuario),
    horario timestamp default now(),
    peso_kg numeric(10,2),
    foto_url varchar(255)
);

create table registros_residuo (
    id_registro serial primary key,
    id_turno integer references turnos(id_turno),
    peso_reciclagem_kg numeric(10,2),
    peso_residuo_kg numeric(10,2)
);

create table alertas (
    id_alerta serial primary key,
    id_maquina integer references maquinas(id_maquina),
	mensagem varchar(255)
);


insert into usuarios (login, senha) values
('davi.oliveira', '123456'),
('supervisor01', 'senha123');

insert into turnos (nome_turno) values
('turno a'), ('turno b'), ('turno c'), ('turno d');

insert into maquinas (nome_maquina, status) values
('fresadora cnc 01', 'disponivel'),
('impressora 3d 02', 'indisponivel'),
('torno mecanico 03', 'alerta/manutencao');

insert into registros_residuo (id_turno, peso_reciclagem_kg, peso_residuo_kg) values
(1, 4800, 1200),
(2, 4950, 1100),
(3, 5200, 950),
(4, 5500, 800);

insert into falhas (id_maquina, id_usuario, peso_kg, foto_url) values
(2, 1, 10.20, '/fotos/falha_impressora02.jpg');

insert into alertas (id_maquina, mensagem) values
(2, 'atencao: limite de desperdicio atingido!');
