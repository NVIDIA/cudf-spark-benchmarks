WITH FilteredCustomers AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           CONCAT(a.ca_street_number, ' ', a.ca_street_name, ', ', a.ca_city, ', ', a.ca_state, ' ', a.ca_zip) AS full_address
    FROM customer c
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
),
SalesData AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2458810 AND 2458830 
    GROUP BY ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT cus.full_name, 
           cus.full_address, 
           COALESCE(sal.total_sales, 0) AS total_sales
    FROM FilteredCustomers cus
    LEFT JOIN SalesData sal ON cus.c_customer_sk = sal.ws_bill_customer_sk
)
SELECT full_name,
       full_address,
       total_sales,
       CASE 
           WHEN total_sales > 1000 THEN 'High Value'
           WHEN total_sales > 500 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value
FROM CombinedData
ORDER BY total_sales DESC
LIMIT 10;