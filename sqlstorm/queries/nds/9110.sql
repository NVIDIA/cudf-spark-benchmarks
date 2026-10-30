
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_net_paid) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_moy BETWEEN 1 AND 6
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_sales
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    ORDER BY cs.total_sales DESC
    LIMIT 10
),
WarehouseSales AS (
    SELECT w.w_warehouse_id, SUM(ws.ws_net_paid) AS total_warehouse_sales
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT tc.c_first_name, tc.c_last_name, tc.total_sales, ws.total_warehouse_sales
FROM TopCustomers tc
JOIN WarehouseSales ws ON tc.total_sales > ws.total_warehouse_sales
ORDER BY tc.total_sales DESC;
