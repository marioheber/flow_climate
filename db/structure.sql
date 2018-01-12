SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE companies (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE companies_id_seq OWNED BY companies.id;


--
-- Name: companies_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE companies_users (
    user_id integer,
    company_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE customers (
    id bigint NOT NULL,
    company_id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: customers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE customers_id_seq OWNED BY customers.id;


--
-- Name: financial_informations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE financial_informations (
    id bigint NOT NULL,
    company_id integer NOT NULL,
    finances_date date NOT NULL,
    income_total numeric NOT NULL,
    expenses_total numeric NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: financial_informations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE financial_informations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: financial_informations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE financial_informations_id_seq OWNED BY financial_informations.id;


--
-- Name: operation_weekly_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE operation_weekly_results (
    id bigint NOT NULL,
    company_id integer NOT NULL,
    result_date date NOT NULL,
    billable_count integer NOT NULL,
    operation_week_value numeric NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: operation_weekly_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE operation_weekly_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: operation_weekly_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE operation_weekly_results_id_seq OWNED BY operation_weekly_results.id;


--
-- Name: project_weekly_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_weekly_results (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    result_date date NOT NULL,
    qty_hours_upstream integer,
    qty_hours_downstream integer,
    throughput integer NOT NULL,
    qty_bugs_opened integer NOT NULL,
    qty_bugs_closed integer NOT NULL,
    qty_hours_bug integer NOT NULL,
    leadtime numeric,
    histogram_first_mode numeric,
    histogram_second_mode numeric,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_weekly_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_weekly_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_weekly_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_weekly_results_id_seq OWNED BY project_weekly_results.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE projects (
    id bigint NOT NULL,
    customer_id integer NOT NULL,
    name character varying NOT NULL,
    status integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    value numeric,
    qty_hours numeric,
    hour_value numeric,
    initial_scope integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: team_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE team_members (
    id bigint NOT NULL,
    company_id integer NOT NULL,
    name character varying NOT NULL,
    monthly_payment numeric NOT NULL,
    hours_per_month integer NOT NULL,
    active boolean DEFAULT true,
    billable boolean DEFAULT true,
    billable_type integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: team_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE team_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE team_members_id_seq OWNED BY team_members.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    email character varying NOT NULL,
    encrypted_password character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    admin boolean DEFAULT false NOT NULL,
    last_company_id integer
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies ALTER COLUMN id SET DEFAULT nextval('companies_id_seq'::regclass);


--
-- Name: customers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY customers ALTER COLUMN id SET DEFAULT nextval('customers_id_seq'::regclass);


--
-- Name: financial_informations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_informations ALTER COLUMN id SET DEFAULT nextval('financial_informations_id_seq'::regclass);


--
-- Name: operation_weekly_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY operation_weekly_results ALTER COLUMN id SET DEFAULT nextval('operation_weekly_results_id_seq'::regclass);


--
-- Name: project_weekly_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_weekly_results ALTER COLUMN id SET DEFAULT nextval('project_weekly_results_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: team_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_members ALTER COLUMN id SET DEFAULT nextval('team_members_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: financial_informations financial_informations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_informations
    ADD CONSTRAINT financial_informations_pkey PRIMARY KEY (id);


--
-- Name: operation_weekly_results operation_weekly_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY operation_weekly_results
    ADD CONSTRAINT operation_weekly_results_pkey PRIMARY KEY (id);


--
-- Name: project_weekly_results project_weekly_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_weekly_results
    ADD CONSTRAINT project_weekly_results_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: team_members team_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_members
    ADD CONSTRAINT team_members_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_companies_users_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_companies_users_on_company_id ON companies_users USING btree (company_id);


--
-- Name: index_companies_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_companies_users_on_user_id ON companies_users USING btree (user_id);


--
-- Name: index_customers_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_customers_on_company_id ON customers USING btree (company_id);


--
-- Name: index_financial_informations_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_financial_informations_on_company_id ON financial_informations USING btree (company_id);


--
-- Name: index_project_weekly_results_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_weekly_results_on_project_id ON project_weekly_results USING btree (project_id);


--
-- Name: index_projects_on_customer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_on_customer_id ON projects USING btree (customer_id);


--
-- Name: index_team_members_on_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_members_on_company_id ON team_members USING btree (company_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: companies_users fk_rails_27539b2fc9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies_users
    ADD CONSTRAINT fk_rails_27539b2fc9 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: team_members fk_rails_3ec60e399b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_members
    ADD CONSTRAINT fk_rails_3ec60e399b FOREIGN KEY (company_id) REFERENCES companies(id);


--
-- Name: projects fk_rails_47c768ed16; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT fk_rails_47c768ed16 FOREIGN KEY (customer_id) REFERENCES customers(id);


--
-- Name: financial_informations fk_rails_573f757bcf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY financial_informations
    ADD CONSTRAINT fk_rails_573f757bcf FOREIGN KEY (company_id) REFERENCES companies(id);


--
-- Name: companies_users fk_rails_667cd952fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY companies_users
    ADD CONSTRAINT fk_rails_667cd952fb FOREIGN KEY (company_id) REFERENCES companies(id);


--
-- Name: users fk_rails_971bf2d9a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_rails_971bf2d9a1 FOREIGN KEY (last_company_id) REFERENCES companies(id);


--
-- Name: project_weekly_results fk_rails_c3c9938173; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_weekly_results
    ADD CONSTRAINT fk_rails_c3c9938173 FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: operation_weekly_results fk_rails_dbd0ae3c1c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY operation_weekly_results
    ADD CONSTRAINT fk_rails_dbd0ae3c1c FOREIGN KEY (company_id) REFERENCES companies(id);


--
-- Name: customers fk_rails_ef51a916ef; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY customers
    ADD CONSTRAINT fk_rails_ef51a916ef FOREIGN KEY (company_id) REFERENCES companies(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20180111164501'),
('20180111170136'),
('20180111180016'),
('20180111232828'),
('20180111234624'),
('20180112002920'),
('20180112010014'),
('20180112010152');


