WITH  category_sales AS (
    SELECT 
        i_category,
        SUM(ws_ext_sales_price) as total_sales,
        COUNT(DISTINCT ws_order_number) as order_count,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY SUM(ws_ext_sales_price) DESC) as category_rank
    FROM 
        item
    JOIN 
        web_sales ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY 
        i_category
),
top_categories AS (
    SELECT 
        i_category,
        total_sales,
        order_count,
        category_rank
    FROM 
        category_sales
    WHERE 
        category_rank <= 10
),
address_info AS (
    SELECT 
        ca_zip,
        ca_city,
        ca_state,
        CASE
            WHEN ca_state IN ('CA', 'NY', 'TX') THEN 'High Population'
            ELSE 'Other'
        END AS population_density
    FROM 
        customer_address
),
sales_by_region AS (
    SELECT 
        addr.ca_state AS state,
        SUM(s.total_sales) AS regional_sales,
        COUNT(s.order_count) AS total_orders,
        MAX(s.total_sales) AS max_sales
    FROM 
        address_info addr
    JOIN 
        top_categories s ON addr.ca_zip LIKE '9%' 
    GROUP BY 
        addr.ca_state
)
SELECT 
    r.state,
    r.regional_sales,
    r.total_orders,
    r.max_sales,
    COALESCE(r.regional_sales / NULLIF(SUM(r.regional_sales) OVER (), 0), 0) AS sales_percentage,
    (SELECT COUNT(DISTINCT ws_order_number) 
     FROM web_sales ws 
     WHERE ws.ws_ship_date_sk > (
         SELECT MIN(ws2.ws_ship_date_sk) 
         FROM web_sales ws2 
         WHERE ws2.ws_ship_date_sk IS NOT NULL)
     AND ws.ws_ship_date_sk < 
         (SELECT MAX(ws3.ws_ship_date_sk) 
         FROM web_sales ws3)) AS total_recent_orders
FROM 
    sales_by_region r
ORDER BY 
    r.regional_sales DESC;