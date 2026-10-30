
WITH CustomerStats AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT c.*, 
           RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_profit DESC) AS rank
    FROM CustomerStats c
)
SELECT t.c_first_name, 
       t.c_last_name, 
       t.cd_gender, 
       t.total_quantity, 
       t.total_profit,
       w.w_warehouse_name,
       w.w_city,
       w.w_state
FROM TopCustomers t
JOIN warehouse w ON t.total_quantity > 100
WHERE t.rank <= 10
   OR (t.cd_marital_status = 'M' AND t.total_profit > 5000)
ORDER BY t.cd_gender, t.total_profit DESC;

