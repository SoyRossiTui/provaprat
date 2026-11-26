Tabelas


CREATE TABLE jogadores (
    id_jogador SERIAL PRIMARY KEY,
    nickname VARCHAR(50) not null UNIQUE,
    email VARCHAR(100) not null UNIQUE,
    senha VARCHAR(150) not null,
    status VARCHAR(10) not null DEFAULT 'ativo'
        CHECK (status IN ('ativo', 'inativo', 'banido')),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE modalidades (
    id_modalidade SERIAL PRIMARY KEY,
    nome VARCHAR(100) not null UNIQUE,
    categoria VARCHAR(50) not null,
    plataforma VARCHAR(50) not null
);

CREATE TABLE torneios (
    id_torneio SERIAL PRIMARY KEY,
    nome VARCHAR(100) not null,
    id_modalidade int not null,
    data_inicio date not null,
    data_fim date not null,
    status VARCHAR(30) not null DEFAULT 'inscricoes_abertas'
    CHECK (status in ('inscricoes_abertas', 'em_andamento', 'finalizado')),

    FOREIGN KEY (id_modalidade)
    REFERENCES modalidades(id_modalidade),
	CHECK (data_fim >= data_inicio)
);

CREATE TABLE inscricoes (
    id_inscricao SERIAL PRIMARY KEY,
    id_jogador int not null,
    id_torneio int not null,
    data_inscricao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) not null DEFAULT 'confirmada'
    CHECK (status in ('confirmada', 'pendente', 'cancelada')),

    FOREIGN KEY (id_jogador)
    REFERENCES jogadores(id_jogador),
	FOREIGN KEY (id_torneio)
    REFERENCES torneios(id_torneio),
	UNIQUE (id_jogador, id_torneio)
);

CREATE TABLE partidas (
    id_partida SERIAL PRIMARY KEY,
    titulo VARCHAR(120) not null,
    id_torneio int not null,
    id_jogador_responsavel int not null,
    data_agendamento TIMESTAMP not null,
    status VARCHAR(20) not null DEFAULT 'agendada'
    CHECK (status in ('agendada', 'em_andamento', 'finalizada', 'cancelada')),
    criada_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_torneio)
    REFERENCES torneios(id_torneio),
	FOREIGN KEY (id_jogador_responsavel)
    REFERENCES jogadores(id_jogador)
);

CREATE TABLE historico_partidas (
    id_historico SERIAL PRIMARY KEY,
    id_partida int not null,
    acao VARCHAR(50) not null,
    descricao VARCHAR(200) not null,
    data_evento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_partida)
        REFERENCES partidas(id_partida)
);


Trigger


CREATE OR REPLACE FUNCTION fn_validar_partida()
RETURNS TRIGGER AS $$
DECLARE
v_status_jogador VARCHAR(20);
BEGIN
    
    SELECT status
    INTO v_status_jogador
    FROM jogadores
    WHERE id_jogador = NEW.id_jogador_responsavel;

    IF NOT FOUND THEN
    RAISE EXCEPTION 'Jogador nao encontrado!';
    END IF;

   
    IF v_status_jogador <> 'ativo' THEN
    RAISE EXCEPTION 'O jogador precisa estar ativo!';
    END IF;

   
    NEW.criada_em := CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_partida();


CREATE OR REPLACE FUNCTION fn_registrar_historico_partida()
RETURNS TRIGGER AS $$
BEGIN
    
    INSERT INTO historico_partidas
    (id_partida, acao, descricao)
    VALUES (
    NEW.id_partida,
    'CRIACAO',
    'Partida cadastrada: ' || NEW.titulo);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER trg_registrar_historico
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico_partida();


Inserts


INSERT INTO jogadores (nickname, email, senha, status) VALUES
('ArthurGamer', 'arthur@email.com', 'senha123', 'ativo'),
('BrayanPro', 'brayan@email.com', 'brayan456', 'ativo'),
('PlayerBanido', 'banido@email.com', 'teste789', 'banido');


INSERT INTO modalidades (nome, categoria, plataforma) VALUES
('Valorant', 'FPS', 'PC'),
('Counter-Strike 2', 'FPS', 'PC'),
('Rocket League', 'Esporte', 'PC/Console');


INSERT INTO torneios
(nome, id_modalidade, data_inicio, data_fim, status) VALUES
('Copa Valorant 2026', 1, '2026-12-01', '2026-12-10', 'inscricoes_abertas'),
('Campeonato CS2 2026', 2, '2026-12-05', '2026-12-15', 'inscricoes_abertas'),
('Liga Rocket League 2026', 3, '2026-12-08', '2026-12-18', 'inscricoes_abertas');


INSERT INTO inscricoes (id_jogador, id_torneio, status) VALUES
(1, 1, 'confirmada'),
(2, 2, 'confirmada'),
(1, 3, 'pendente');


INSERT INTO partidas
(titulo, id_torneio, id_jogador_responsavel, data_agendamento, status)
VALUES
('ArthurGamer x Jogador 2', 1, 1, '2026-12-02 19:00:00', 'agendada'),
('BrayanPro x Jogador 3', 2, 2, '2026-12-06 20:00:00', 'agendada'),
('ArthurGamer x BrayanPro', 3, 1, '2026-12-09 18:30:00', 'agendada');


Funções


CREATE OR REPLACE FUNCTION fn_buscar_jogadores(p_termo TEXT)
RETURNS TABLE (
    id_jogador int,
    nickname VARCHAR(50),
    email VARCHAR(100),
    status VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
RETURN QUERY
SELECT
        j.id_jogador,
        j.nickname,
        j.email,
        j.status
FROM jogadores j
WHERE j.nickname ilike '%' || p_termo || '%'
OR j.email ilike '%' || p_termo || '%';
END;
$$;


CREATE OR REPLACE FUNCTION fn_buscar_jogadores(p_termo TEXT)
RETURNS TABLE (
    id_jogador INTEGER,
    nickname VARCHAR(50),
    email VARCHAR(100),
    status VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
RETURN QUERY
SELECT
        j.id_jogador,
        j.nickname,
        j.email,
        j.status
FROM jogadores j
WHERE j.nickname ilike '%' || p_termo || '%'
OR j.email ilike '%' || p_termo || '%';
END;
$$;


Views


CREATE OR REPLACE VIEW vw_painel_principal AS
SELECT
    j.nickname,
    p.titulo AS titulo_partida,
    m.categoria AS modalidade,
    p.data_agendamento AS data_partida,
    p.status
	
FROM partidas p
INNER JOIN jogadores j
ON j.id_jogador = p.id_jogador_responsavel
INNER JOIN torneios t
ON t.id_torneio = p.id_torneio
INNER JOIN modalidades m
ON m.id_modalidade = t.id_modalidade;


CREATE OR REPLACE VIEW vw_cronograma_partidas AS
SELECT
    p.id_partida,
    p.titulo AS titulo_partida,
    p.data_agendamento,
    p.status,
    (p.data_agendamento::DATE - CURRENT_DATE) AS dias_restantes,
    j.nickname AS jogador_responsavel
	
FROM partidas p
INNER JOIN jogadores j
ON j.id_jogador = p.id_jogador_responsavel
ORDER BY p.data_agendamento ASC;


Testes


SELECT * FROM jogadores;
SELECT * FROM modalidades;
SELECT * FROM torneios;
SELECT * FROM inscricoes;
SELECT * FROM partidas;
SELECT * FROM historico_partidas;
SELECT * FROM fn_buscar_jogadores('Arthur');
SELECT * FROM vw_painel_principal;
SELECT * FROM vw_cronograma_partidas;
