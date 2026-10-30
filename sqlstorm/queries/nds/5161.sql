
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status, 
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_performers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.total_profit
    FROM 
        ranked_customers rc
    WHERE 
        rc.gender_rank <= 10
),
recent_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws.ws_item_sk, ws.ws_order_number, ws.ws_sold_date_sk
)
SELECT 
    tp.c_customer_sk,
    tp.c_first_name,
    tp.c_last_name,
    rp.ws_item_sk,
    SUM(rp.total_quantity) AS total_quantity_sold,
    SUM(CASE WHEN rp.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) THEN 1 ELSE 0 END) AS recent_sales_count
FROM 
    top_performers tp
JOIN 
    recent_sales rp ON tp.c_customer_sk = rp.ws_order_number
GROUP BY 
    tp.c_customer_sk, tp.c_first_name, tp.c_last_name, rp.ws_item_sk
ORDER BY 
    total_quantity_sold DESC, tp.c_last_name, tp.c_first_name;
