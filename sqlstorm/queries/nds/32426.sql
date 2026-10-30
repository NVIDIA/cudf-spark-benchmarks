
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_gender = 'F' THEN 'Female'
            WHEN cd_gender = 'M' THEN 'Male'
            ELSE 'Unknown' 
        END AS gender,
        cd_marital_status AS marital_status,
        cd_purchase_estimate,
        COALESCE(hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
top_items AS (
    SELECT 
        ws_item_sk,
        SUM(total_profit) AS item_profit
    FROM 
        sales_summary
    WHERE 
        rn = 1
    GROUP BY 
        ws_item_sk
    ORDER BY 
        item_profit DESC
    LIMIT 10
)
SELECT 
    c.gender,
    c.marital_status,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(s.total_quantity) AS total_quantity,
    SUM(s.total_profit) AS total_profit
FROM 
    customer_data c
JOIN 
    sales_summary s ON c.c_customer_sk = s.ws_item_sk
JOIN 
    top_items t ON s.ws_item_sk = t.ws_item_sk
GROUP BY 
    c.gender, c.marital_status
HAVING 
    SUM(s.total_profit) > 0
ORDER BY 
    total_profit DESC;
