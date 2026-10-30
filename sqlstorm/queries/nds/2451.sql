
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_month = 'Y')
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        customer_info ci
    JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_order_number
    WHERE 
        rs.profit_rank = 1
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
    HAVING 
        SUM(rs.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM web_sales)
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_sales,
    COUNT(ws.ws_order_number) AS order_count
FROM 
    high_value_customers hvc
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = hvc.c_customer_sk
GROUP BY 
    hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name
ORDER BY 
    total_sales DESC, order_count DESC
LIMIT 10;
