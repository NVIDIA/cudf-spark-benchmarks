
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_summary AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
average_sales AS (
    SELECT 
        ws_item_sk,
        AVG(ws_ext_sales_price) AS average_price,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    sd.ws_item_sk,
    sd.ws_quantity,
    COALESCE(asales.average_price, 0) AS average_price,
    CASE 
        WHEN cs.unique_orders > 5 THEN 'High'
        WHEN cs.unique_orders BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS order_frequency_category,
    RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
FROM 
    customer_summary cs
JOIN 
    sales_data sd ON sd.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 20)
LEFT JOIN 
    average_sales asales ON asales.ws_item_sk = sd.ws_item_sk
WHERE 
    sd.sales_rank = 1
ORDER BY 
    cs.total_profit DESC, cs.c_customer_id
LIMIT 100;
