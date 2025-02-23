-- CREATE DATABASE online_services_market_environment;

CREATE TYPE license_status_t AS ENUM ('active', 'expired', 'revoked', 'pending');
CREATE TYPE suggestion_status_t AS ENUM ('pending', 'accepted', 'rejected', 'completed');

CREATE TABLE category (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE subset_category (
    subset_category_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category_id INT REFERENCES category(category_id) ON DELETE CASCADE
);

CREATE TABLE service (
    service_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    available_at_the_customers_location BOOLEAN NOT NULL,
    available_at_the_experts_location BOOLEAN NOT NULL,
    subset_category_id INT REFERENCES subset_category(subset_category_id) ON DELETE CASCADE,
    min_advertising_cost DECIMAL(10, 2) NOT NULL DEFAULT 0,
    max_advertising_cost DECIMAL(10, 2) NOT NULL DEFAULT 9999999999.99,
    CHECK (min_advertising_cost <= max_advertising_cost),
    CHECK (available_at_the_customers_location OR available_at_the_experts_location)
);

CREATE TABLE expert (
    expert_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    radius_of_service INT NOT NULL, -- real or decimal?
    category_id INT REFERENCES category(category_id) ON DELETE SET NULL
);

CREATE TABLE license_type (
    license_type_id SERIAL PRIMARY KEY, 
    worth DECIMAL(10,2) NOT NULL,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE service_license_type (
    service_id INT NOT NULL REFERENCES service(service_id) ON DELETE CASCADE,
    license_type_id INT NOT NULL REFERENCES license_type(license_type_id) ON DELETE CASCADE,
    optional BOOLEAN NOT NULL,
    PRIMARY KEY (service_id, license_type_id)
);

CREATE TABLE license (
    license_id SERIAL PRIMARY KEY,
    registration_number VARCHAR(50) NOT NULL, -- this column unique or (license_type_id, registration_number) unique? (match with er)
    status license_status_t NOT NULL,
    expiration_date DATE NOT NULL,
    expert_id INT REFERENCES expert(expert_id) ON DELETE CASCADE,
    license_type_id INT REFERENCES license_type(license_type_id) ON DELETE CASCADE,
    UNIQUE (license_type_id, registration_number)
);

CREATE TABLE providing_services (
    expert_id INT NOT NULL REFERENCES expert(expert_id) ON DELETE CASCADE,
    service_id INT NOT NULL REFERENCES service(service_id) ON DELETE CASCADE,
    advertising_cost DECIMAL(10,2) NOT NULL,
    provides_at_the_customers_location BOOLEAN NOT NULL,
    provides_at_the_experts_location BOOLEAN NOT NULL,
    PRIMARY KEY (expert_id, service_id),
    CHECK (provides_at_the_customers_location OR provides_at_the_experts_location)
);

CREATE OR REPLACE FUNCTION check_location_availability()
RETURNS TRIGGER AS $$
BEGIN
    IF ((NOT (SELECT available_at_the_customers_location FROM service WHERE NEW.service_id = service.service_id) AND
        NEW.provides_at_the_customers_location) OR
        (NOT (SELECT available_at_the_experts_location FROM service WHERE NEW.service_id = service.service_id) AND
        NEW.provides_at_the_experts_location)) THEN
        RAISE EXCEPTION 'experts availability doesn''t match service''s.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_location_availability
BEFORE INSERT OR UPDATE ON providing_services
FOR EACH ROW EXECUTE FUNCTION check_location_availability();

CREATE OR REPLACE FUNCTION check_expert_service_category()
RETURNS TRIGGER AS $$
BEGIN
    IF ((SELECT category_id FROM subset_category WHERE subset_category_id = (SELECT subset_category_id FROM service WHERE NEW.service_id = service.service_id)) <>
        (SELECT category_id FROM expert WHERE NEW.expert_id = expert.expert_id)) THEN
        RAISE EXCEPTION 'service must be in expert''s category';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_expert_service_category
BEFORE INSERT OR UPDATE ON providing_services
FOR EACH ROW EXECUTE FUNCTION check_expert_service_category();

CREATE OR REPLACE FUNCTION check_advertising_cost_range()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.advertising_cost NOT BETWEEN 
        (SELECT min_advertising_cost FROM service WHERE service.service_id = NEW.service_id) 
        AND 
        (SELECT max_advertising_cost FROM service WHERE service.service_id = NEW.service_id)) THEN
        RAISE EXCEPTION 'advertising cost should be in service specific range';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_advertising_cost_range
BEFORE INSERT OR UPDATE ON providing_services
FOR EACH ROW EXECUTE FUNCTION check_advertising_cost_range();


CREATE TABLE question_forms (
    question_form_id SERIAL PRIMARY KEY,
    question_text TEXT NOT NULL
);

CREATE TABLE multiple_choice_questions (
    multiple_choice_question_id INT PRIMARY KEY REFERENCES question_forms(question_form_id) ON DELETE CASCADE,
    number_of_selectable_options INT CHECK (number_of_selectable_options > 0)
);

CREATE TABLE textual_questions (
    textual_question_id INT PRIMARY KEY REFERENCES question_forms(question_form_id) ON DELETE CASCADE,
    maximum_length_of_answer INT CHECK (maximum_length_of_answer > 0)
);

CREATE TABLE numerical_questions (
    numerical_question_id INT PRIMARY KEY REFERENCES question_forms(question_form_id) ON DELETE CASCADE,
    answer_range NUMRANGE NOT NULL 
);

CREATE TABLE service_question (
    service_question_id SERIAL PRIMARY KEY,
    number INT NOT NULL,
    service_id INT REFERENCES service(service_id) ON DELETE CASCADE,
    question_form_id INT REFERENCES question_forms(question_form_id) on DELETE RESTRICT,
    UNIQUE (service_id, question_form_id), -- same question can't appear twice in a service's question set
    UNIQUE (service_id, number) -- two questions in a service's question set can't have the same number (questions are ordered by number)
);

CREATE TABLE filters (
    filter_id SERIAL PRIMARY KEY,
    acceptable_options JSON NOT NULL, -- JSON or array of option numbers?
    description TEXT NOT NULL,
    expert_id INT NOT NULL REFERENCES expert(expert_id) ON DELETE CASCADE,
    service_question_id INT NOT NULL REFERENCES service_question(service_question_id) ON DELETE CASCADE,
    UNIQUE (expert_id, service_question_id)
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(15),
    CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CHECK (phone ~ '^(\+98|0)?9\d{9}$')
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    service_id INT NOT NULL REFERENCES service(service_id) ON DELETE CASCADE
);

CREATE TABLE answers (
    answer_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE
);

CREATE TABLE options (
    option_id SERIAL PRIMARY KEY,
    text VARCHAR(255) NOT NULL,
    number INT NOT NULL,
    multiple_choice_question_id INT REFERENCES multiple_choice_questions(multiple_choice_question_id) ON DELETE CASCADE,
    UNIQUE (multiple_choice_question_id, number)
);

CREATE TABLE multiple_choice_answers (
    multiple_choice_answer_id INT PRIMARY KEY REFERENCES answers(answer_id) ON DELETE CASCADE,
    selected_options JSON NOT NULL, -- JSON or array of option numbers?
    multiple_choice_question_id INT REFERENCES multiple_choice_questions(multiple_choice_question_id) ON DELETE CASCADE
);

CREATE TABLE textual_answers (
    textual_answer_id INT PRIMARY KEY REFERENCES answers(answer_id) ON DELETE CASCADE,
    answer_text TEXT NOT NULL,
    textual_question_id INT REFERENCES textual_questions(textual_question_id) ON DELETE CASCADE
);

CREATE TABLE numerical_answers (
    numerical_answer_id INT PRIMARY KEY REFERENCES answers(answer_id) ON DELETE CASCADE,
    answer_value DECIMAL(10,2) NOT NULL,
    numerical_question_id INT REFERENCES numerical_questions(numerical_question_id) ON DELETE CASCADE
);

CREATE TABLE suggestions (
    suggestion_id SERIAL PRIMARY KEY,
    suggested_price DECIMAL(10,2) NOT NULL,
    status suggestion_status_t,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    expert_id INT NOt NULL REFERENCES expert(expert_id) ON DELETE CASCADE,
    UNIQUE (order_id, expert_id)
);

CREATE TABLE feedbacks (
    feedback_id SERIAL PRIMARY KEY,
    text_comment TEXT NOT NULL,
    score INT CHECK (score BETWEEN 1 AND 5),
    suggestion_id INT NOT NULL UNIQUE REFERENCES suggestions(suggestion_id) ON DELETE CASCADE -- add suggestions status complete check
);

CREATE OR REPLACE FUNCTION check_feedback_suggestion_status()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT status FROM suggestions WHERE suggestion_id = NEW.suggestion_id) <> 'completed'::suggestion_status_t THEN
        RAISE EXCEPTION 'feedback can only be added for completed orders';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_feedback_suggestion_status
BEFORE INSERT ON feedbacks
FOR EACH ROW EXECUTE FUNCTION check_feedback_suggestion_status();