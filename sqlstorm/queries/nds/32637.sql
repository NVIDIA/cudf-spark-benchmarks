
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
TopSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_item_sk) AS total_transactions
    FROM 
        SalesCTE
    WHERE 
        rn <= 10
    GROUP BY 
        ws_item_sk
),
PopularItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        CASE WHEN total_sales > 1000 THEN 'Yes' ELSE 'No' END AS is_popular,
        ts.total_sales,
        ts.total_transactions
    FROM 
        TopSales ts
    JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
)
SELECT 
    pi.i_item_id,
    pi.i_item_desc,
    pi.total_sales,
    pi.total_transactions,
    COALESCE(ca.ca_city, 'Unknown') AS shipping_city,
    COALESCE(sm.sm_type, 'Standard') AS shipping_mode,
    CASE 
        WHEN pi.is_popular = 'Yes' THEN 'Highly Recommended' 
        ELSE 'Standard Item' 
    END AS recommendation
FROM 
    PopularItems pi
LEFT JOIN 
    customer_address ca ON pi.total_transactions = ca.ca_address_sk
LEFT JOIN 
    ship_mode sm ON pi.total_transactions = sm.sm_ship_mode_sk
WHERE 
    pi.total_sales BETWEEN 500 AND 2000 
ORDER BY 
    pi.total_sales DESC
LIMIT 20;
