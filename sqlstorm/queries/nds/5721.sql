
WITH aggregated_sales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM catalog_sales
    GROUP BY cs_item_sk
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_profit_items AS (
    SELECT 
        sales.cs_item_sk,
        sales.total_quantity,
        sales.total_profit,
        customer.cd_gender,
        customer.cd_marital_status
    FROM aggregated_sales sales
    JOIN customer_details customer ON sales.cs_item_sk IN (
        SELECT i_item_sk
        FROM item
        WHERE i_current_price > 50
    )
    WHERE sales.total_profit > 1000
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    h.total_quantity,
    h.total_profit,
    h.cd_gender,
    h.cd_marital_status
FROM high_profit_items h
JOIN item ON h.cs_item_sk = item.i_item_sk
ORDER BY h.total_profit DESC
LIMIT 100;
