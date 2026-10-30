
SELECT c_first_name, c_last_name, ca_city, ca_state, d_year
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
WHERE d.d_year = 2023
ORDER BY c_first_name, c_last_name;
