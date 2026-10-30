
WITH Ranked_Sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
Top_Sales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.ws_order_number, 
        rs.total_sales
    FROM 
        Ranked_Sales rs
    WHERE 
        rs.rn = 1
),
Store_Customer_Data AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
),
Sales_Analysis AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_sales,
        scd.total_quantity,
        scd.distinct_customers,
        COALESCE(ts.total_sales / NULLIF(scd.total_quantity, 0), 0) AS avg_sales_per_quantity
    FROM 
        Top_Sales ts
    LEFT JOIN 
        Store_Customer_Data scd ON ts.ws_item_sk = scd.cs_item_sk
)
SELECT 
    sa.ws_item_sk,
    sa.total_sales,
    sa.total_quantity,
    sa.distinct_customers,
    sa.avg_sales_per_quantity,
    (CASE 
        WHEN sa.avg_sales_per_quantity >= 100 THEN 'High Performer'
        WHEN sa.avg_sales_per_quantity BETWEEN 50 AND 99 THEN 'Average Performer'
        ELSE 'Low Performer'
    END) AS performance_category
FROM 
    Sales_Analysis sa
WHERE 
    sa.total_sales > 1000
ORDER BY 
    sa.avg_sales_per_quantity DESC
LIMIT 10;
