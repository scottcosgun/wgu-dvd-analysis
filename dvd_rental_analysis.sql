-- create detailed table 
CREATE TABLE detailed_fewest_rentals ( 
    customer_id INT PRIMARY KEY, 
    customer_name VARCHAR(100 NOT NULL), 
    email VARCHAR(100) NOT NULL, 
    phone VARCHAR(20) NOT NULL, 
    address VARCHAR(100) NOT NULL, 
    city VARCHAR(50) NOT NULL, 
    district VARCHAR(100) NOT NULL, 
    country VARCHAR(50) NOT NULL, 
    postal_code VARCHAR(10) NOT NULL, 
    count_rentals SMALLINT NOT NULL, 
    amount_spent DECIMAL(5,2) 
); 
 
-- create summary table 
CREATE TABLE summary_fewest_rentals( 
    customer_id INT PRIMARY KEY, 
    count_rentals SMALLINT NOT NULL, 
    amount_spent DECIMAL(5,2) 
);

-- insert data into detailed table
INSERT INTO fewest_rentals_detailed( 
    customer_id, 
    customer_name, 
    email, 
    phone, 
    address, 
    city, 
    district, 
    country, 
    postal_code, 
    count_rentals, 
    amount_spent 
) 
SELECT customer.customer_id, concatenate_name(customer.first_name, customer.last_name), 
customer.email, address.phone, address.address, address.district, city.city, country.country, 
address.postal_code, COUNT(rental.customer_id), SUM(amount) 
FROM customer 
INNER JOIN address ON customer.address_id = address.address_id 
INNER JOIN city ON address.city_id = city.city_id 
INNER JOIN country ON city.country_id = country.country_id 
INNER JOIN rental ON customer.customer_id = rental.customer_id 
INNER JOIN payment ON rental.rental_id = payment.rental_id 
GROUP BY customer.customer_id, customer.first_name, customer.last_name, customer.email, 
address.phone, address.address, address.district, city.city, country.country, address.postal_code 
ORDER BY COUNT(rental.customer_id) ASC 
LIMIT 50;


-- trigger to update the summary table
CREATE OR REPLACE FUNCTION update_summary() 
RETURNS TRIGGER AS $update_summary_trigger$ 
    BEGIN 
        INSERT INTO fewest_rentals_summary(customer_id, count_rentals, amount_spent) 
        VALUES (new.customer_id, new.count_rentals, new.amount_spent); 
        RETURN NEW; 
    END; 
$update_summary_trigger$ LANGUAGE plpgsql; 
 
CREATE TRIGGER update_summary_trigger 
AFTER INSERT ON fewest_rentals_detailed 
FOR EACH ROW 
EXECUTE PROCEDURE update_summary();

-- stored procedure to refresh tables
CREATE OR REPLACE PROCEDURE refresh_fewest_rentals() 
AS $$ 
BEGIN 
    DELETE FROM fewest_rentals_detailed; 
    DELETE FROM fewest_rentals_summary; 
 
    INSERT INTO fewest_rentals_detailed( 
        customer_id, 
        name, 
        email, 
        phone, 
        address, 
        city, 
        district, 
        country, 
        postal_code, 
        count_rentals, 
        amount_spent 
    ) 
    SELECT customer.customer_id, concatenate_name(customer.first_name, 
    customer.last_name), customer.email, address.phone, address.address, address.district, 
    city.city, country.country, address.postal_code, COUNT(rental.customer_id), 
    SUM(amount) 
    FROM customer 
    INNER JOIN address ON customer.address_id = address.address_id 
    INNER JOIN city ON address.city_id = city.city_id 
    INNER JOIN country ON city.country_id = country.country_id 
    INNER JOIN rental ON customer.customer_id = rental.customer_id 
    INNER JOIN payment ON rental.rental_id = payment.rental_id 
    GROUP BY customer.customer_id, customer.first_name, customer.last_name, 
    customer.email, address.phone, address.address, address.district, city.city, 
    country.country, address.postal_code 
    ORDER BY COUNT(rental.customer_id) ASC 
    LIMIT 50; 
END; 
$$ LANGUAGE plpgsql;