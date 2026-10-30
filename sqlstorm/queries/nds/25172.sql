
WITH StringBenchmark AS (
  SELECT
    c.c_first_name,
    c.c_last_name,
    ca.ca_street_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    UPPER(c.c_last_name) AS upper_last_name,
    LOWER(c.c_first_name) AS lower_first_name,
    CHAR_LENGTH(c.c_email_address) AS email_length,
    REPLACE(c.c_email_address, '@', '[at]') AS email_obfuscated,
    TRIM(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city)) AS full_address,
    SUBSTRING(ca.ca_zip, 1, 5) AS short_zip
  FROM customer c
  JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE
    CHAR_LENGTH(c.c_first_name) > 2 AND
    c.c_email_address LIKE '%@%.%'
)
SELECT 
  full_name,
  upper_last_name,
  lower_first_name,
  email_length,
  email_obfuscated,
  full_address,
  short_zip
FROM StringBenchmark
ORDER BY full_name;
