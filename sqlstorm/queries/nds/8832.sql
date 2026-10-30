
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451962 AND 2452285 
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.total_profit,
        rc.total_orders
    FROM ranked_customers rc
    WHERE rc.profit_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_profit,
    tc.total_orders,
    w.w_warehouse_name,
    COUNT(ws.ws_item_sk) AS items_purchased
FROM top_customers tc
JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_profit,
    tc.total_orders,
    w.w_warehouse_name
ORDER BY 
    tc.total_profit DESC, 
    w.w_warehouse_name;
