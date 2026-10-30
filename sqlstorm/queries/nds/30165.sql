
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), ranked_items AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name, 
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_profit, 0) AS total_profit,
        sd.order_count,
        sd.rank
    FROM 
        item
    LEFT JOIN 
        sales_data sd ON item.i_item_sk = sd.ws_item_sk
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), top_customers AS (
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
        ci.purchase_rank <= 10
)
SELECT 
    ri.i_product_name,
    ri.total_quantity,
    ri.total_profit,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status
FROM 
    ranked_items ri
JOIN 
    top_customers tc ON tc.c_customer_sk IS NOT NULL
WHERE 
    (ri.total_profit > 5000 OR ri.total_quantity > 100)
    AND tc.cd_gender = 'F'
    AND ri.rank = 1
ORDER BY 
    ri.total_profit DESC
LIMIT 50;
