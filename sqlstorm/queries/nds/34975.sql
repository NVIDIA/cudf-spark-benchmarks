
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CAST('2002-10-01' AS DATE) - INTERVAL '1 year')
    GROUP BY 
        ws_item_sk
    
    UNION ALL
    
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid_inc_tax) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CAST('2002-10-01' AS DATE) - INTERVAL '1 year')
    GROUP BY 
        cs_item_sk
)
, ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(sd.total_quantity, 0) AS quantity_sold,
        COALESCE(sd.total_sales, 0.00) AS sales_revenue
    FROM 
        item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
)
SELECT 
    ia.c_first_name || ' ' || ia.c_last_name AS customer_name,
    ia.c_customer_id,
    COUNT(DISTINCT ia.c_customer_sk) AS number_of_customers,
    SUM(COALESCE(isales.quantity_sold, 0)) AS total_item_sold,
    SUM(COALESCE(isales.sales_revenue, 0)) AS total_sales_revenue,
    MAX(CASE WHEN id.d_dow = 0 THEN 'Sunday' ELSE 'Weekday' END) AS sale_day_type,
    STRING_AGG(DISTINCT ip.p_promo_name, ', ') AS promo_names
FROM 
    customer ia 
LEFT JOIN 
    ItemSales isales ON isales.i_item_sk IN (
        SELECT DISTINCT ws_item_sk 
        FROM web_sales 
        WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    )
LEFT JOIN 
    promotion ip ON ip.p_item_sk = isales.i_item_sk
LEFT JOIN 
    date_dim id ON id.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
GROUP BY 
    ia.c_customer_id, ia.c_first_name, ia.c_last_name
HAVING 
    SUM(COALESCE(isales.sales_revenue, 0)) > 10000
ORDER BY 
    total_sales_revenue DESC
LIMIT 10;
