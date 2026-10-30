
WITH  demographic_data AS (
    SELECT 
        cd_demo_sk, 
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ws_net_profit, 0) AS total_web_sales,
        COALESCE(ss_net_profit, 0) AS total_store_sales,
        CASE 
            WHEN ws_net_profit > ss_net_profit THEN 'Web'
            WHEN ss_net_profit > ws_net_profit THEN 'Store'
            ELSE 'Equal'
        END AS preferred_sales_channel
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
),
ranked_sales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_store_sales,
        cs.preferred_sales_channel,
        dd.cd_marital_status,
        dd.cd_gender,
        dd.rank
    FROM customer_sales cs
    INNER JOIN demographic_data dd ON cs.c_customer_sk = dd.cd_demo_sk
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_store_sales,
    r.preferred_sales_channel,
    r.cd_marital_status,
    r.cd_gender,
    CASE 
        WHEN r.cd_marital_status = 'S' AND r.total_web_sales > 1000 THEN 'Single High Roller'
        WHEN r.cd_marital_status = 'M' AND r.total_store_sales > 1000 THEN 'Married Big Spender'
        ELSE 'Regular Customer'
    END AS customer_type
FROM ranked_sales r
WHERE r.rank = 1
ORDER BY 
    CASE 
        WHEN r.cd_gender = 'M' THEN 1 
        WHEN r.cd_gender = 'F' THEN 2
        ELSE 3 
    END,
    r.total_web_sales DESC,
    r.total_store_sales ASC
LIMIT 10
OFFSET 5;
