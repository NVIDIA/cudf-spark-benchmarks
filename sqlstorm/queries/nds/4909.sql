
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        COALESCE(SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 0) AS rolling_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.avg_order_value,
        RANK() OVER (ORDER BY ci.avg_order_value DESC) AS rank
    FROM 
        customer_info ci
    WHERE 
        ci.total_orders > 5
)

SELECT 
    s.ws_sold_date_sk,
    s.ws_item_sk,
    s.ws_quantity,
    s.rolling_profit,
    tc.cd_gender,
    tc.avg_order_value
FROM 
    sales_data s
JOIN 
    top_customers tc ON s.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_class_id IN (3, 5))
WHERE 
    s.profit_rank <= 10
ORDER BY 
    s.ws_sold_date_sk, tc.avg_order_value DESC;
