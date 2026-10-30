
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.total_sales,
           ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS ranking
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
)
SELECT tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_sales,
       ca.ca_city, ca.ca_state
FROM TopCustomers tc
JOIN customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE tc.ranking <= 10 AND ca.ca_country = 'USA'
ORDER BY tc.total_sales DESC;
