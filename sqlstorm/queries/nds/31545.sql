
WITH  sales_cte AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
    UNION ALL
    SELECT 
        cs_item_sk, 
        cs_order_number, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk, cs_order_number
),
aggregated_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(s.total_quantity) AS aggregate_quantity,
        SUM(s.total_sales) AS aggregate_sales
    FROM 
        sales_cte s
    JOIN 
        item ON item.i_item_sk = s.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_product_name
),
windowed_sales AS (
    SELECT 
        a.*, 
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN aggregate_sales > 1000 THEN 1 ELSE 0 END ORDER BY aggregate_sales DESC) AS sales_rank
    FROM 
        aggregated_sales a
)

SELECT 
    a.*, 
    b.ca_city, 
    b.ca_state, 
    c.cd_gender, 
    d.d_date
FROM 
    windowed_sales a
LEFT JOIN 
    customer_address b ON a.i_item_id = b.ca_address_id
JOIN 
    customer_demographics c ON b.ca_address_sk = c.cd_demo_sk
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
WHERE 
    a.aggregate_quantity > 50
    AND COALESCE(c.cd_marital_status, 'N') = 'M'
    AND (c.cd_purchase_estimate IS NOT NULL OR (c.cd_credit_rating IS NULL AND c.cd_dep_count > 0))
ORDER BY 
    a.aggregate_sales DESC
LIMIT 100;
