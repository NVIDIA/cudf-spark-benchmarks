WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        ws_item_sk
), 
Sales_Analysis AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_sales, 0) AS total_sales,
        s.rank
    FROM 
        item AS i
    LEFT JOIN Sales_CTE AS s ON i.i_item_sk = s.ws_item_sk
)
SELECT 
    sa.i_item_id,
    sa.i_product_name,
    sa.total_quantity,
    sa.total_sales,
    CASE 
        WHEN sa.total_sales > 1000 THEN 'High Performer'
        WHEN sa.total_sales BETWEEN 500 AND 1000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    Sales_Analysis AS sa
WHERE 
    sa.rank <= 10
ORDER BY 
    sa.total_sales DESC
LIMIT 10;