
WITH  CustomerReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
RecentWebSales AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MAX(d_date_sk) - 30
        FROM date_dim
        WHERE d_current_month = 'Y'
    )
    GROUP BY ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
           COALESCE(rws.total_net_profit, 0) AS total_net_profit,
           CASE 
               WHEN COALESCE(cr.total_return_quantity, 0) > 10 THEN 'High Return'
               ELSE 'Normal'
           END AS customer_return_status
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN RecentWebSales rws ON c.c_customer_sk = rws.ws_bill_customer_sk
    WHERE (COALESCE(cr.total_return_quantity, 0) > 5 OR 
           COALESCE(rws.total_net_profit, 0) > 500)
)
SELECT hvc.c_customer_sk, 
       hvc.c_first_name, 
       hvc.c_last_name, 
       hvc.total_return_quantity, 
       hvc.total_net_profit, 
       hvc.customer_return_status,
       wa.w_warehouse_name,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       AVG(ws.ws_net_profit) AS avg_order_profit
FROM HighValueCustomers hvc
LEFT JOIN web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN warehouse wa ON ws.ws_warehouse_sk = wa.w_warehouse_sk
GROUP BY hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name, 
         hvc.total_return_quantity, hvc.total_net_profit, 
         hvc.customer_return_status, wa.w_warehouse_name
HAVING COUNT(DISTINCT ws.ws_order_number) > 0
ORDER BY hvc.total_net_profit DESC, hvc.c_last_name ASC;
