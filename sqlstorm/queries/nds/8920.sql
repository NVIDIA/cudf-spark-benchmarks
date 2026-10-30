WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2459184 AND 2459516 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.total_sales
    FROM customer c
    JOIN CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    ORDER BY cs.total_sales DESC
    LIMIT 10
),
CustomerAddress AS (
    SELECT c.c_customer_sk, 
           ca.ca_city, 
           ca.ca_state, 
           ca.ca_country
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
)
SELECT tc.c_customer_sk, 
       tc.c_first_name, 
       tc.c_last_name, 
       ca.ca_city, 
       ca.ca_state, 
       ca.ca_country, 
       tc.total_sales
FROM TopCustomers tc
JOIN CustomerAddress ca ON tc.c_customer_sk = ca.c_customer_sk
ORDER BY tc.total_sales DESC;