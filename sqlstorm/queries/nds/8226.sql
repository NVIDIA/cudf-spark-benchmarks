
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.total_sales, 
           cs.total_orders,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT tc.c_first_name, 
       tc.c_last_name, 
       tc.total_sales, 
       tc.total_orders,
       cd.cd_gender,
       cd.cd_marital_status,
       cd.cd_education_status
FROM TopCustomers tc
JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC;
