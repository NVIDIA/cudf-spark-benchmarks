
WITH CustomerAddress AS (
    SELECT ca_address_sk, 
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
           ca_city, ca_state
    FROM customer_address
), CustomerDetails AS (
    SELECT c.c_customer_sk, 
           c.c_first_name || ' ' || c.c_last_name AS full_name, 
           cd.cd_gender, 
           cd.cd_marital_status,
           cd.cd_education_status,
           ca.full_address, 
           ca.ca_city, 
           ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerAddress ca ON c.c_current_addr_sk = ca.ca_address_sk
), PopularCities AS (
    SELECT full_address, 
           ca_city, 
           ca_state, 
           COUNT(*) AS address_count
    FROM CustomerDetails
    GROUP BY full_address, ca_city, ca_state
    ORDER BY address_count DESC
    LIMIT 10
)
SELECT DISTINCT d.d_date AS sale_date,
       c.full_name,
       c.cd_gender,
       c.cd_marital_status,
       c.cd_education_status,
       p.ca_city,
       p.ca_state,
       p.address_count,
       SUM(ws.ws_ext_sales_price) AS total_sales
FROM web_sales ws
JOIN CustomerDetails c ON ws.ws_ship_customer_sk = c.c_customer_sk
JOIN PopularCities p ON c.full_address = p.full_address
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2023
GROUP BY d.d_date, c.full_name, c.cd_gender, c.cd_marital_status, c.cd_education_status, p.ca_city, p.ca_state, p.address_count
ORDER BY total_sales DESC;
