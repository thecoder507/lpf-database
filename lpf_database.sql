--
-- PostgreSQL database dump
--

-- Dumped from database version 13.21
-- Dumped by pg_dump version 13.21

-- Started on 2025-09-24 11:07:07

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 202 (class 1259 OID 24597)
-- Name: conferencias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conferencias (
    id integer NOT NULL,
    nombre character varying(10) NOT NULL,
    CONSTRAINT conferencias_nombre_check CHECK (((nombre)::text = ANY ((ARRAY['este'::character varying, 'oeste'::character varying])::text[])))
);


ALTER TABLE public.conferencias OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 24612)
-- Name: equipos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipos (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    apodo character varying(50),
    ciudad character varying(50) NOT NULL,
    estadio_id integer,
    fundacion date,
    conferencia_id integer
);


ALTER TABLE public.equipos OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 24624)
-- Name: estadios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estadios (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL,
    ubicacion character varying(150),
    capacidad integer
);


ALTER TABLE public.estadios OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 24636)
-- Name: fases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fases (
    id integer NOT NULL,
    torneo_id integer NOT NULL,
    tipo character varying(30) NOT NULL,
    CONSTRAINT fases_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['clasificatoria'::character varying, 'repechaje'::character varying, 'semifinal'::character varying, 'final'::character varying])::text[])))
);


ALTER TABLE public.fases OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 24647)
-- Name: partidos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partidos (
    id integer NOT NULL,
    fase_id integer NOT NULL,
    equipo_local_id integer,
    equipo_visitante_id integer,
    estadio_id integer,
    jornada integer,
    fecha date,
    hora time without time zone,
    goles_loc integer NOT NULL,
    goles_vis integer NOT NULL,
    tipo_partido character varying(20) NOT NULL,
    CONSTRAINT partidos_goles_no_negativo_check CHECK (((goles_loc >= 0) AND (goles_vis >= 0))),
    CONSTRAINT partidos_jornada_no_negativo_check CHECK ((jornada > 0)),
    CONSTRAINT partidos_no_equipos_iguales_check CHECK ((equipo_local_id <> equipo_visitante_id)),
    CONSTRAINT partidos_tipo_partido_check CHECK (((tipo_partido)::text = ANY ((ARRAY['jornada'::character varying, 'ida'::character varying, 'vuelta'::character varying, 'unico'::character varying])::text[])))
);


ALTER TABLE public.partidos OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 32878)
-- Name: goles_equipo_vista; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.goles_equipo_vista AS
 SELECT e.nombre AS equipo,
    sum(t.goles_favor) AS goles_a_favor,
    sum(t.goles_contra) AS goles_en_contra,
    (sum(t.goles_favor) - sum(t.goles_contra)) AS dg
   FROM (( SELECT partidos.equipo_local_id AS equipo_id,
            partidos.goles_loc AS goles_favor,
            partidos.goles_vis AS goles_contra
           FROM public.partidos
        UNION ALL
         SELECT partidos.equipo_visitante_id AS equipo_id,
            partidos.goles_vis AS goles_favor,
            partidos.goles_loc AS goles_contra
           FROM public.partidos) t
     JOIN public.equipos e ON ((e.id = t.equipo_id)))
  GROUP BY e.nombre
  ORDER BY (sum(t.goles_favor) - sum(t.goles_contra)) DESC;


ALTER TABLE public.goles_equipo_vista OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 32899)
-- Name: partidos_info_vista; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.partidos_info_vista AS
 SELECT partido.id,
    fases.tipo,
    partido.jornada,
    equipo_local.nombre AS local,
    equipo_visitante.nombre AS visitante,
    concat(partido.goles_loc, ' - ', partido.goles_vis) AS resultado,
    partido.fecha,
    partido.hora,
    estadios.nombre AS estadio
   FROM ((((public.partidos partido
     JOIN public.equipos equipo_local ON ((partido.equipo_local_id = equipo_local.id)))
     JOIN public.equipos equipo_visitante ON ((partido.equipo_visitante_id = equipo_visitante.id)))
     JOIN public.estadios ON ((partido.estadio_id = estadios.id)))
     JOIN public.fases ON ((partido.fase_id = fases.id)));


ALTER TABLE public.partidos_info_vista OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 32893)
-- Name: tabla_posiciones_vista; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.tabla_posiciones_vista AS
 SELECT c.nombre AS conferencia,
    e.nombre AS equipo,
    count(*) AS partidos_jugados,
    sum(t.goles_favor) AS gf,
    sum(t.goles_contra) AS gc,
    (sum(t.goles_favor) - sum(t.goles_contra)) AS dg,
    sum(
        CASE
            WHEN (t.goles_favor > t.goles_contra) THEN 1
            ELSE 0
        END) AS ganados,
    sum(
        CASE
            WHEN (t.goles_favor = t.goles_contra) THEN 1
            ELSE 0
        END) AS empates,
    sum(
        CASE
            WHEN (t.goles_favor < t.goles_contra) THEN 1
            ELSE 0
        END) AS perdidos,
    sum(
        CASE
            WHEN (t.goles_favor > t.goles_contra) THEN 3
            WHEN (t.goles_favor = t.goles_contra) THEN 1
            ELSE 0
        END) AS puntos
   FROM ((( SELECT partidos.equipo_local_id AS equipo_id,
            partidos.goles_loc AS goles_favor,
            partidos.goles_vis AS goles_contra
           FROM public.partidos
        UNION ALL
         SELECT partidos.equipo_visitante_id AS equipo_id,
            partidos.goles_vis AS goles_favor,
            partidos.goles_loc AS goles_contra
           FROM public.partidos) t
     JOIN public.equipos e ON ((t.equipo_id = e.id)))
     JOIN public.conferencias c ON ((e.conferencia_id = c.id)))
  GROUP BY c.nombre, e.nombre
  ORDER BY (sum(
        CASE
            WHEN (t.goles_favor > t.goles_contra) THEN 3
            WHEN (t.goles_favor = t.goles_contra) THEN 1
            ELSE 0
        END)) DESC, (sum(t.goles_favor) - sum(t.goles_contra)) DESC, (sum(t.goles_favor)) DESC;


ALTER TABLE public.tabla_posiciones_vista OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 24577)
-- Name: temporadas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.temporadas (
    id integer NOT NULL,
    "año" integer NOT NULL
);


ALTER TABLE public.temporadas OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 24582)
-- Name: torneos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.torneos (
    id integer NOT NULL,
    temporada_id integer,
    nombre character varying(20) NOT NULL,
    CONSTRAINT torneos_nombre_check CHECK (((nombre)::text = ANY ((ARRAY['apertura'::character varying, 'clausura'::character varying])::text[])))
);


ALTER TABLE public.torneos OWNER TO postgres;

--
-- TOC entry 3065 (class 0 OID 24597)
-- Dependencies: 202
-- Data for Name: conferencias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conferencias (id, nombre) FROM stdin;
1	este
2	oeste
\.


--
-- TOC entry 3066 (class 0 OID 24612)
-- Dependencies: 203
-- Data for Name: equipos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipos (id, nombre, apodo, ciudad, estadio_id, fundacion, conferencia_id) FROM stdin;
1	Alianza	Los Pericos	Panamá, Panamá	1	1963-03-02	1
2	Árabe Unido	El Expreso Azul	Colón, Colón	2	1994-04-28	1
5	Plaza Amador	Los Leones	Panamá, Panamá	4	1955-04-25	1
6	Potros del Este	Potros	Panamá, Panamá	1	2022-02-01	1
8	Sporting San Miguelito	Académicos	San Miguelito, Panamá	5	1989-02-14	1
9	Tauro	Los Toros	Panamá, Panamá	6	1984-09-22	1
3	Atlético Independiente	CAI	La Chorrera, Panamá Oeste	2	1983-02-12	2
4	Herrera	Herreranos	Chitré, Herrera	3	2016-07-05	2
7	San Francisco	Los Monjes	La Chorrera, Panamá Oeste	2	1971-09-29	2
10	Universitario	La U	Penonomé, Coclé	7	2018-06-13	2
11	Umecit	Umecistas	Atalaya, Veraguas	8	2002-12-16	2
12	Veraguas United	Los Vikingos	Santiago, Veraguas	8	2022-02-03	2
\.


--
-- TOC entry 3067 (class 0 OID 24624)
-- Dependencies: 204
-- Data for Name: estadios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.estadios (id, nombre, ubicacion, capacidad) FROM stdin;
1	Javier Cruz García	Panamá, Panamá	700
2	Agustín "Muquita" Sánchez	La Chorrera, Panamá Oeste	3000
3	Los Milagros	Chitré, Herrera	1000
4	COS Sports Plaza	Panamá, Panamá	1100
5	Los Andes	San Miguelito, Panamá	1450
6	Rommel Fernández	Panamá, Panamá	32450
7	Universidad Latina	Penonomé, Coclé	3500
8	Rafael Rodríguez	Santiago, Veraguas	500
9	Estadio Virgilio Tejeira	Penonomé, Panamá	900
\.


--
-- TOC entry 3068 (class 0 OID 24636)
-- Dependencies: 205
-- Data for Name: fases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fases (id, torneo_id, tipo) FROM stdin;
1	1	clasificatoria
2	1	repechaje
3	1	semifinal
4	1	final
\.


--
-- TOC entry 3069 (class 0 OID 24647)
-- Dependencies: 206
-- Data for Name: partidos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.partidos (id, fase_id, equipo_local_id, equipo_visitante_id, estadio_id, jornada, fecha, hora, goles_loc, goles_vis, tipo_partido) FROM stdin;
1	1	1	9	1	1	2024-01-20	16:00:00	1	0	jornada
2	1	8	2	5	1	2024-01-20	20:30:00	0	3	jornada
3	1	5	6	1	1	2024-01-21	16:00:00	3	1	jornada
4	1	10	3	7	1	2024-01-19	20:00:00	1	1	jornada
5	1	7	11	2	1	2024-01-20	18:15:00	0	0	jornada
6	1	12	4	8	1	2024-01-21	18:15:00	0	2	jornada
7	1	6	1	1	2	2024-01-27	16:00:00	1	1	jornada
8	1	8	5	5	2	2024-01-27	20:30:00	1	1	jornada
9	1	2	9	2	2	2024-01-28	16:00:00	0	2	jornada
10	1	7	10	2	2	2024-01-26	20:00:00	1	1	jornada
11	1	11	4	8	2	2024-01-27	18:15:00	3	2	jornada
12	1	12	3	8	2	2024-01-28	18:15:00	1	2	jornada
13	1	1	5	1	3	2024-02-03	16:00:00	0	2	jornada
15	1	2	6	2	3	2024-02-04	20:30:00	0	1	jornada
16	1	3	7	2	3	2024-02-03	18:15:00	3	0	jornada
17	1	4	10	3	3	2024-02-03	20:30:00	3	3	jornada
18	1	11	12	8	3	2024-02-04	18:15:00	1	1	jornada
62	1	6	7	1	11	2024-04-06	16:00:00	2	3	jornada
63	1	10	5	7	11	2024-04-06	18:15:00	0	4	jornada
14	1	9	8	1	3	2024-02-03	16:00:00	1	0	jornada
19	1	6	9	1	4	2024-02-07	16:00:00	1	1	jornada
20	1	8	1	5	4	2024-02-07	18:15:00	2	3	jornada
21	1	2	5	2	4	2024-02-08	20:30:00	2	0	jornada
22	1	4	3	3	4	2024-02-06	18:00:00	1	1	jornada
23	1	7	12	2	4	2024-02-07	20:30:00	2	1	jornada
24	1	10	11	7	4	2024-02-08	20:30:00	1	0	jornada
25	1	6	8	1	5	2024-02-17	16:00:00	1	0	jornada
26	1	9	5	6	5	2024-02-17	18:15:00	0	1	jornada
27	1	1	2	1	5	2024-02-18	16:00:00	2	2	jornada
28	1	7	4	2	5	2024-02-16	20:00:00	2	2	jornada
29	1	3	11	2	5	2024-02-17	20:30:00	1	2	jornada
30	1	12	10	8	5	2024-02-18	18:15:00	1	1	jornada
31	1	4	1	3	6	2024-02-23	20:00:00	1	2	jornada
33	1	11	8	8	6	2024-02-24	18:15:00	1	0	jornada
34	1	10	6	7	6	2024-02-24	20:30:00	1	3	jornada
36	1	3	5	2	6	2024-03-12	20:00:00	0	1	jornada
64	1	11	9	8	11	2024-04-06	20:30:00	1	2	jornada
65	1	1	12	1	11	2024-04-07	16:00:00	3	2	jornada
32	1	2	7	1	6	2024-02-24	16:00:00	0	0	jornada
67	1	6	2	1	12	2024-04-13	16:00:00	4	2	jornada
35	1	9	12	1	6	2024-02-25	16:00:00	2	1	jornada
37	1	1	10	1	7	2024-03-02	16:00:00	1	0	jornada
39	1	12	2	8	7	2024-03-02	20:30:00	3	2	jornada
40	1	6	11	1	7	2024-03-03	16:00:00	0	0	jornada
41	1	7	9	2	7	2024-03-03	18:15:00	0	3	jornada
42	1	8	3	5	7	2024-03-04	20:00:00	1	0	jornada
68	1	8	9	5	12	2024-04-13	20:30:00	2	1	jornada
69	1	5	1	1	12	2024-04-14	16:00:00	1	1	jornada
70	1	7	3	2	12	2024-04-12	20:00:00	3	1	jornada
38	1	5	4	5	7	2024-03-02	18:15:00	1	2	jornada
43	1	8	7	5	8	2024-03-08	20:00:00	0	1	jornada
45	1	3	1	2	8	2024-03-09	18:15:00	5	1	jornada
46	1	10	9	7	8	2024-03-09	20:30:00	2	2	jornada
47	1	11	2	8	8	2024-03-10	16:00:00	0	0	jornada
71	1	12	11	8	12	2024-04-13	18:15:00	2	1	jornada
44	1	4	6	9	8	2024-03-09	16:00:00	1	2	jornada
72	1	10	4	7	12	2024-04-14	18:15:00	1	2	jornada
48	1	5	12	5	8	2024-03-10	18:15:00	2	1	jornada
49	1	7	5	2	9	2024-03-15	20:00:00	2	0	jornada
50	1	1	11	1	9	2024-03-16	16:00:00	0	1	jornada
51	1	3	6	2	9	2024-03-16	18:15:00	0	1	jornada
54	1	12	8	8	9	2024-03-17	18:15:00	1	1	jornada
52	1	2	10	5	9	2024-03-16	20:30:00	0	2	jornada
53	1	9	4	1	9	2024-03-17	16:00:00	1	2	jornada
55	1	7	1	2	10	2024-03-22	20:00:00	1	0	jornada
57	1	4	2	8	10	2024-03-23	18:15:00	3	0	jornada
58	1	8	10	5	10	2024-03-23	20:30:00	1	1	jornada
59	1	6	12	1	10	2024-03-24	16:00:00	2	1	jornada
74	1	5	8	2	13	2024-04-16	18:15:00	1	2	jornada
75	1	6	1	1	13	2024-04-17	16:00:00	0	0	jornada
76	1	10	7	7	13	2024-04-16	20:30:00	0	1	jornada
77	1	4	11	8	13	2024-04-17	18:15:00	2	1	jornada
78	1	3	12	2	13	2024-04-17	20:30:00	3	1	jornada
79	1	2	1	2	14	2024-04-19	20:00:00	0	2	jornada
80	1	5	9	4	14	2024-04-20	20:30:00	0	3	jornada
81	1	8	6	5	14	2024-04-21	18:15:00	3	2	jornada
82	1	4	7	8	14	2024-04-20	16:00:00	0	1	jornada
83	1	10	12	7	14	2024-04-20	18:15:00	2	1	jornada
84	1	11	3	8	14	2024-04-21	16:00:00	0	0	jornada
85	1	2	8	1	15	2024-04-27	16:00:00	1	1	jornada
88	1	11	7	8	15	2024-04-27	16:00:00	1	0	jornada
91	1	5	2	4	16	2024-05-02	16:00:00	1	0	jornada
94	1	3	4	2	16	2024-05-02	20:00:00	1	0	jornada
73	1	9	2	1	13	2024-04-16	16:00:00	2	0	jornada
66	1	4	8	5	11	2024-04-07	18:15:00	1	1	jornada
61	1	2	3	5	11	2024-04-05	20:00:00	1	4	jornada
92	1	9	6	2	16	2024-05-02	16:00:00	0	0	jornada
86	1	6	5	5	15	2024-04-27	20:00:00	1	0	jornada
87	1	9	1	2	15	2024-04-27	20:00:00	0	0	jornada
95	1	12	7	8	16	2024-05-02	20:00:00	0	1	jornada
93	1	1	8	1	16	2024-05-02	16:00:00	0	1	jornada
96	1	11	10	5	16	2024-05-02	20:00:00	1	1	jornada
56	1	9	3	1	10	2024-03-23	16:00:00	1	0	jornada
60	1	5	11	5	10	2024-03-24	18:15:00	3	1	jornada
89	1	3	10	2	15	2024-04-27	16:00:00	2	1	jornada
90	1	4	12	9	15	2024-04-27	16:00:00	4	3	jornada
97	2	9	3	1	\N	2024-05-11	15:00:00	4	1	unico
98	2	4	5	8	\N	2024-05-12	17:00:00	1	2	unico
99	3	9	7	1	\N	2024-05-18	16:00:00	2	1	ida
100	3	7	9	2	\N	2024-05-24	20:30:00	0	0	vuelta
101	3	5	6	4	\N	2024-05-18	20:00:00	1	1	ida
102	3	6	5	5	\N	2024-05-25	20:00:00	0	0	vuelta
103	4	9	5	6	\N	2024-06-01	19:15:00	2	0	unico
\.


--
-- TOC entry 3063 (class 0 OID 24577)
-- Dependencies: 200
-- Data for Name: temporadas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.temporadas (id, "año") FROM stdin;
1	2024
\.


--
-- TOC entry 3064 (class 0 OID 24582)
-- Dependencies: 201
-- Data for Name: torneos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.torneos (id, temporada_id, nombre) FROM stdin;
1	1	apertura
2	1	clausura
\.


--
-- TOC entry 2901 (class 2606 OID 24603)
-- Name: conferencias conferencias_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conferencias
    ADD CONSTRAINT conferencias_nombre_key UNIQUE (nombre);


--
-- TOC entry 2903 (class 2606 OID 24601)
-- Name: conferencias conferencias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conferencias
    ADD CONSTRAINT conferencias_pkey PRIMARY KEY (id);


--
-- TOC entry 2906 (class 2606 OID 24618)
-- Name: equipos equipos_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipos
    ADD CONSTRAINT equipos_nombre_key UNIQUE (nombre);


--
-- TOC entry 2908 (class 2606 OID 24616)
-- Name: equipos equipos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipos
    ADD CONSTRAINT equipos_pkey PRIMARY KEY (id);


--
-- TOC entry 2910 (class 2606 OID 24630)
-- Name: estadios estadios_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estadios
    ADD CONSTRAINT estadios_nombre_key UNIQUE (nombre);


--
-- TOC entry 2912 (class 2606 OID 24628)
-- Name: estadios estadios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estadios
    ADD CONSTRAINT estadios_pkey PRIMARY KEY (id);


--
-- TOC entry 2916 (class 2606 OID 24640)
-- Name: fases fases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fases
    ADD CONSTRAINT fases_pkey PRIMARY KEY (id);


--
-- TOC entry 2922 (class 2606 OID 24651)
-- Name: partidos partidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partidos
    ADD CONSTRAINT partidos_pkey PRIMARY KEY (id);


--
-- TOC entry 2893 (class 2606 OID 24678)
-- Name: temporadas temporadas_año_uq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.temporadas
    ADD CONSTRAINT "temporadas_año_uq" UNIQUE ("año");


--
-- TOC entry 2895 (class 2606 OID 24581)
-- Name: temporadas temporadas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.temporadas
    ADD CONSTRAINT temporadas_pkey PRIMARY KEY (id);


--
-- TOC entry 2897 (class 2606 OID 24680)
-- Name: torneos torneos_nombre_uq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.torneos
    ADD CONSTRAINT torneos_nombre_uq UNIQUE (nombre);


--
-- TOC entry 2899 (class 2606 OID 24586)
-- Name: torneos torneos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.torneos
    ADD CONSTRAINT torneos_pkey PRIMARY KEY (id);


--
-- TOC entry 2914 (class 2606 OID 24672)
-- Name: estadios unq_estadio_nombre; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estadios
    ADD CONSTRAINT unq_estadio_nombre UNIQUE (nombre);


--
-- TOC entry 2904 (class 1259 OID 24691)
-- Name: equipos_nombre_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX equipos_nombre_idx ON public.equipos USING btree (nombre);


--
-- TOC entry 2917 (class 1259 OID 24689)
-- Name: partidos_equipo_local_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partidos_equipo_local_id_idx ON public.partidos USING btree (equipo_local_id);


--
-- TOC entry 2918 (class 1259 OID 24690)
-- Name: partidos_equipo_visitante_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partidos_equipo_visitante_id_idx ON public.partidos USING btree (equipo_visitante_id);


--
-- TOC entry 2919 (class 1259 OID 32904)
-- Name: partidos_fase_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partidos_fase_id_idx ON public.partidos USING btree (fase_id);


--
-- TOC entry 2920 (class 1259 OID 24692)
-- Name: partidos_jornada_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX partidos_jornada_idx ON public.partidos USING btree (jornada);


--
-- TOC entry 2924 (class 2606 OID 24619)
-- Name: equipos equipos_conferencia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipos
    ADD CONSTRAINT equipos_conferencia_id_fkey FOREIGN KEY (conferencia_id) REFERENCES public.conferencias(id);


--
-- TOC entry 2925 (class 2606 OID 24631)
-- Name: equipos equipos_estadio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipos
    ADD CONSTRAINT equipos_estadio_id_fkey FOREIGN KEY (estadio_id) REFERENCES public.estadios(id);


--
-- TOC entry 2926 (class 2606 OID 24641)
-- Name: fases fases_torneo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fases
    ADD CONSTRAINT fases_torneo_id_fkey FOREIGN KEY (torneo_id) REFERENCES public.torneos(id);


--
-- TOC entry 2927 (class 2606 OID 24652)
-- Name: partidos partidos_equipo_local_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partidos
    ADD CONSTRAINT partidos_equipo_local_id_fkey FOREIGN KEY (equipo_local_id) REFERENCES public.equipos(id);


--
-- TOC entry 2928 (class 2606 OID 24657)
-- Name: partidos partidos_equipo_visitante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partidos
    ADD CONSTRAINT partidos_equipo_visitante_id_fkey FOREIGN KEY (equipo_visitante_id) REFERENCES public.equipos(id);


--
-- TOC entry 2929 (class 2606 OID 24662)
-- Name: partidos partidos_estadio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partidos
    ADD CONSTRAINT partidos_estadio_id_fkey FOREIGN KEY (estadio_id) REFERENCES public.estadios(id);


--
-- TOC entry 2923 (class 2606 OID 24587)
-- Name: torneos torneos_temporada_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.torneos
    ADD CONSTRAINT torneos_temporada_id_fkey FOREIGN KEY (temporada_id) REFERENCES public.temporadas(id);


--
-- TOC entry 3075 (class 0 OID 0)
-- Dependencies: 3
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA public TO readonly;
GRANT USAGE ON SCHEMA public TO readwrite;


--
-- TOC entry 3076 (class 0 OID 0)
-- Dependencies: 202
-- Name: TABLE conferencias; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.conferencias TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.conferencias TO readwrite;


--
-- TOC entry 3077 (class 0 OID 0)
-- Dependencies: 203
-- Name: TABLE equipos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.equipos TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.equipos TO readwrite;


--
-- TOC entry 3078 (class 0 OID 0)
-- Dependencies: 204
-- Name: TABLE estadios; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.estadios TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.estadios TO readwrite;


--
-- TOC entry 3079 (class 0 OID 0)
-- Dependencies: 205
-- Name: TABLE fases; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.fases TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.fases TO readwrite;


--
-- TOC entry 3080 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE partidos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.partidos TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partidos TO readwrite;


--
-- TOC entry 3081 (class 0 OID 0)
-- Dependencies: 207
-- Name: TABLE goles_equipo_vista; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.goles_equipo_vista TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.goles_equipo_vista TO readwrite;


--
-- TOC entry 3082 (class 0 OID 0)
-- Dependencies: 209
-- Name: TABLE partidos_info_vista; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.partidos_info_vista TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.partidos_info_vista TO readwrite;


--
-- TOC entry 3083 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE tabla_posiciones_vista; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.tabla_posiciones_vista TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.tabla_posiciones_vista TO readwrite;


--
-- TOC entry 3084 (class 0 OID 0)
-- Dependencies: 200
-- Name: TABLE temporadas; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.temporadas TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.temporadas TO readwrite;


--
-- TOC entry 3085 (class 0 OID 0)
-- Dependencies: 201
-- Name: TABLE torneos; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.torneos TO readonly;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.torneos TO readwrite;


--
-- TOC entry 1745 (class 826 OID 24687)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES  TO readonly;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES  TO readwrite;


-- Completed on 2025-09-24 11:07:07

--
-- PostgreSQL database dump complete
--

