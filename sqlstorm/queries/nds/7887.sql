
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales, 
           COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451112 AND 2451500
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
Demographics AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status
    FROM customer_demographics cd
    JOIN CustomerSales cs ON cs.c_customer_sk = cd.cd_demo_sk
), 
AddressInfo AS (
    SELECT ca.ca_address_sk, 
           ca.ca_city, 
           ca.ca_state, 
           ca.ca_country
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT cs.c_first_name, 
       cs.c_last_name, 
       ds.cd_gender, 
       ds.cd_marital_status, 
       ds.cd_education_status, 
       ai.ca_city, 
       ai.ca_state, 
       ai.ca_country, 
       cs.total_sales, 
       cs.order_count
FROM CustomerSales cs
JOIN Demographics ds ON cs.c_customer_sk = ds.cd_demo_sk
JOIN AddressInfo ai ON cs.c_customer_sk = ai.ca_address_sk
WHERE cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
ORDER BY cs.total_sales DESC
LIMIT 10;
