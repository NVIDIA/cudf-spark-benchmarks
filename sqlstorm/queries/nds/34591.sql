
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458486 AND 2458618 
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_income_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
high_income_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate 
    FROM 
        customer_info ci
    WHERE 
        ci.hd_income_band_sk IS NOT NULL
        AND ci.gender_income_rank <= 10
),
top_sales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_net_profit) AS total_net_profit
    FROM 
        web_sales s
    GROUP BY 
        s.ws_item_sk
    HAVING 
        SUM(s.ws_net_profit) > 500
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    s.total_net_profit,
    CASE 
        WHEN c.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status,
    COUNT(DISTINCT r.cr_order_number) AS total_returns
FROM 
    high_income_customers c
JOIN 
    top_sales s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN 
    catalog_returns r ON s.ws_item_sk = r.cr_item_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    s.total_net_profit,
    c.cd_marital_status
ORDER BY 
    s.total_net_profit DESC 
LIMIT 15;
