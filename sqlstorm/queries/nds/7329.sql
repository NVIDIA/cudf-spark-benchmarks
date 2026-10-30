
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_product_name,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
top_sales AS (
    SELECT 
        *
    FROM 
        ranked_sales
    WHERE 
        rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(ts.ws_sales_price) AS total_sales,
    SUM(ts.ws_net_profit) AS total_profit
FROM 
    top_sales ts
JOIN 
    web_sales ws ON ts.ws_order_number = ws.ws_order_number
JOIN 
    customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
GROUP BY 
    ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status
ORDER BY 
    total_profit DESC
LIMIT 10;
