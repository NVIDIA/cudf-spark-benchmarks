
WITH  cte_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rk
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MAX(ws_sold_date_sk) 
        FROM web_sales
        WHERE ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    )
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) AS rk
    FROM catalog_sales 
    WHERE cs_sold_date_sk >= (
        SELECT MAX(cs_sold_date_sk) 
        FROM catalog_sales
        WHERE cs_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    )
),
aggregated_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(cte.ws_quantity) AS total_web_sales_quantity,
        SUM(cte.ws_net_profit) AS total_web_sales_profit,
        COUNT(DISTINCT cte.ws_sold_date_sk) AS web_sales_days,
        SUM(CASE WHEN cte.rk = 1 THEN cte.ws_sales_price ELSE 0 END) AS latest_web_sales_price
    FROM cte_sales cte
    JOIN item ON item.i_item_sk = cte.ws_item_sk
    WHERE cte.ws_quantity IS NOT NULL
    GROUP BY item.i_item_id, item.i_product_name
)
SELECT
    customer.c_customer_id,
    customer.c_first_name,
    customer.c_last_name,
    ada.ca_city,
    ada.ca_state,
    AVG(ads.total_web_sales_quantity) AS avg_web_sales_quantity,
    SUM(ads.total_web_sales_profit) AS total_web_sales_profit
FROM 
    customer
JOIN 
    customer_address ada ON customer.c_current_addr_sk = ada.ca_address_sk
LEFT JOIN 
    aggregated_sales ads ON ads.i_item_id IN (
        SELECT i_item_id 
        FROM item 
        WHERE i_class = 'electronics'
    )
WHERE 
    customer.c_birth_year = (
        SELECT MAX(c_birth_year) 
        FROM customer 
        WHERE c_birth_year IS NOT NULL
    )
AND ada.ca_state IS NOT NULL
GROUP BY 
    customer.c_customer_id, customer.c_first_name, customer.c_last_name, ada.ca_city, ada.ca_state
ORDER BY 
    total_web_sales_profit DESC
LIMIT 50;
