
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_item_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(NULLIF(i.i_brand, ''), 'Unknown Brand') AS item_brand,
        COALESCE(NULLIF(i.i_category, ''), 'Unknown Category') AS item_category,
        i.i_current_price
    FROM 
        item i
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        ci.customer_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate
    FROM 
        customer_info ci
    WHERE 
        ci.rank <= 10
)
SELECT 
    ti.item_brand,
    ti.item_category,
    ss.total_quantity,
    ss.total_profit,
    tc.customer_name,
    tc.cd_gender,
    tc.cd_marital_status
FROM 
    sales_summary ss
JOIN 
    item_info ti ON ss.ws_item_sk = ti.i_item_sk
LEFT JOIN 
    top_customers tc ON ss.total_quantity > 50
WHERE 
    (ti.i_current_price > 20.00 OR ss.total_profit < 1000)
    AND tc.customer_name IS NOT NULL
ORDER BY 
    ss.total_profit DESC
LIMIT 100;
