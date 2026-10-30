
WITH TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_profit DESC
    LIMIT 10
), 
SalesSummary AS (
    SELECT d.d_year, 
           SUM(ws.ws_quantity) AS total_quantity_sold, 
           SUM(ws.ws_net_paid) AS total_sales, 
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
), 
WarehousePerformance AS (
    SELECT w.w_warehouse_id, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
           SUM(ws.ws_net_profit) AS overall_profit
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
)
SELECT tc.c_first_name, 
       tc.c_last_name, 
       ts.d_year, 
       ts.total_quantity_sold, 
       ts.total_sales, 
       ts.total_profit, 
       wp.w_warehouse_id, 
       wp.total_orders, 
       wp.overall_profit
FROM TopCustomers tc
JOIN SalesSummary ts ON ts.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
JOIN WarehousePerformance wp ON wp.total_orders > 100
ORDER BY ts.total_profit DESC, wp.overall_profit DESC;
