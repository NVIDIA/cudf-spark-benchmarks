
WITH  sales_rank AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 4000 AND 5000
    GROUP BY ws_item_sk
), 
high_sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    INNER JOIN sales_rank sr ON i.i_item_sk = sr.ws_item_sk
    WHERE sr.rn <= 10
    GROUP BY i.i_item_id, i.i_item_desc
),
customer_demographics_filtered AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 500
    AND cd.cd_gender IS NOT NULL
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    h.i_item_id,
    h.i_item_desc,
    h.total_profit,
    h.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM high_sales h
JOIN customer_demographics_filtered cd ON h.total_profit > (SELECT AVG(total_profit) FROM high_sales)
ORDER BY h.total_profit DESC, cd.customer_count DESC
LIMIT 10;
