
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name,
           SUM(ws.ws_ext_sales_price) AS total_sales
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
           cs.total_sales
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_sales > (
        SELECT AVG(total_sales) 
        FROM CustomerSales
    )
    ORDER BY cs.total_sales DESC
    LIMIT 10
),
ShippingMethods AS (
    SELECT DISTINCT sm.sm_ship_mode_id, 
           sm.sm_type
    FROM ship_mode sm
    JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    WHERE ws.ws_ship_date_sk BETWEEN 1000 AND 2000
)
SELECT tc.c_first_name,
       tc.c_last_name,
       tc.total_sales,
       sm.sm_ship_mode_id,
       sm.sm_type
FROM TopCustomers tc
CROSS JOIN ShippingMethods sm
ORDER BY tc.total_sales DESC, sm.sm_type;
