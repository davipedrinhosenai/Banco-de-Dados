create table alunos (
	id serial primary key,
	nome varchar(100) not null,
	email varchar(100) unique not null,
	cpf varchar(11) unique not null,
	telefone varchar(20) not null,
	data_cadastro timestamp default current_timestamp
);

create table planos(
	id serial primary key,
	nome varchar(50) unique not null,
	valor_mensal_base decimal(10,2) check (valor_mensal_base > 0) not null
);

create table modalidades(
	id serial primary key,
	plano_id int references planos(id),
	nome varchar(100) not null,
	sala varchar(20) not null,
    capacidade_maxima int check (capacidade_maxima > 0) not null,
    disponivel boolean default true
);

create table matriculas (
    id serial primary key,
    aluno_id int references alunos(id),
    data_inicio timestamp default current_timestamp,
    status varchar(20) default 'ativa' check (status in ('ativa', 'cancelada', 'trancada'))
);

create table itens_matricula (
    id serial primary key,
    matricula_id int references matriculas(id),
    modalidade_id int references modalidades(id),
    duracao_meses int check (duracao_meses > 0) not null,
    valor_mensal_aplicado decimal(10,2) check (valor_mensal_aplicado > 0) not null,
    taxa_adesao decimal(10,2) check (taxa_adesao >= 0) default 0.00
);


-- inserts
insert into planos (nome, valor_mensal_base) values 
('vip premium', 220.00), 
('fitness standard', 140.00), 
('basic fit', 90.00);

insert into modalidades (plano_id, nome, sala, capacidade_maxima, disponivel) values 
(1, 'crossfit pro', 'arena 01', 15, true),
(2, 'pilates avançado', 'studio 02', 10, true),
(3, 'musculação livre', 'salão principal', 50, true);

insert into alunos (nome, email, cpf, telefone) values 
('carlos silva', 'carlos@email.com', '11122233344', '11999990000'),
('ana lima', 'ana@email.com', '22233344455', '11988880000'),
('beatriz costa', 'bea@email.com', '33344455566', '11977770000');

insert into matriculas (aluno_id, status) values 
(1, 'ativa'), 
(1, 'ativa'), 
(2, 'ativa'), 
(3, 'cancelada');

insert into itens_matricula (matricula_id, modalidade_id, duracao_meses, valor_mensal_aplicado, taxa_adesao) values 
(1, 1, 6, 220.00, 50.00),
(2, 2, 3, 140.00, 30.00),
(3, 3, 12, 90.00, 0.00),
(4, 1, 1, 220.00, 50.00);


--q1
create or replace view vw_modalidades_custo_estimado as
select 
    m.nome as modalidade,
    m.sala,
    p.nome as plano,
    round(p.valor_mensal_base * 1.10, 2) as valor_mensal_ajustado
from 
    modalidades m
join 
    planos p on m.plano_id = p.id
order by 
    valor_mensal_ajustado desc;

--q2
create view vw_matriculas_ativas as
select
	a.nome as aluno,
	a.cpf,
	moda.nome as modalidade,
	moda.sala,
	im.duracao_meses,
	mat.data_inicio
from matriculas mat
join alunos a on mat.aluno_id = a.id
join itens_matricula im on mat.id = im.matricula_id
join modalidades moda on im.modalidade_id = moda.id
where mat.status = 'ativa';

--q3
create view vw_alunos_vip as
select 
    a.nome as aluno, 
    count(mat.id) as total_matriculas, 
    sum((im.valor_mensal_aplicado * im.duracao_meses) + im.taxa_adesao) as total_investido
from alunos a
join matriculas mat on a.id = mat.aluno_id
join itens_matricula im on mat.id = im.matricula_id
where mat.status = 'ativa'
group by a.id, a.nome
having sum((im.valor_mensal_aplicado * im.duracao_meses) + im.taxa_adesao) > 1000.00;

--q4
select moda.*, plan.nome as plano, plan.valor_mensal_base
from modalidades moda
join planos plan on moda.plano_id = plan.id
where moda.capacidade_maxima >= 15 
  and plan.valor_mensal_base > 100.00 
  and moda.disponivel = true;

--q5
create view vw_faturamento_medio_plano as
select 
    plan.nome as plano, 
    sum((imat.valor_mensal_aplicado * imat.duracao_meses) + imat.taxa_adesao) as faturamento_total,
    round(avg(imat.duracao_meses), 1) as media_meses_contratados
from itens_matricula imat
join matriculas mat on imat.matricula_id = mat.id
join modalidades moda on imat.modalidade_id = moda.id
join planos plan on moda.plano_id = plan.id
where mat.status = 'ativa'
group by plan.nome;