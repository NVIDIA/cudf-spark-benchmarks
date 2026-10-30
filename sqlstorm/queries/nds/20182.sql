
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
address_count AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses
    FROM 
        customer_address AS ca
    GROUP BY 
        ca.ca_country
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.order_count, 0) AS order_count,
    COALESCE(rs.total_quantity, 0) AS total_quantity,
    COALESCE(rs.total_sales, 0) AS total_sales,
    ac.unique_addresses,
    (CASE 
        WHEN ac.unique_addresses IS NULL THEN 'No Information' 
        ELSE ac.ca_country 
    END) AS country_info
FROM 
    item AS i
LEFT JOIN 
    ranked_sales AS rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    address_count AS ac ON i.i_brand_id = ac.unique_addresses
WHERE 
    (rs.total_sales > 1000 OR rs.order_count > 5) 
    AND (i.i_color IS NULL OR i.i_size LIKE 'M%')
    AND (EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_item_sk = i.i_item_sk 
                  AND ss.ss_net_profit > 0.0) 
          OR NOT EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk))
ORDER BY 
    COALESCE(rs.total_sales, 0) DESC NULLS LAST, 
    i.i_item_desc
LIMIT 50;
