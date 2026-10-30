
WITH  SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IS NOT NULL
),
AggregateSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(DISTINCT sd.ws_order_number) AS total_orders
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_sold_date_sk
)
SELECT 
    d.d_date AS sale_date,
    COALESCE(a.total_quantity, 0) AS total_quantity,
    COALESCE(a.total_sales, 0) AS total_sales,
    COALESCE(a.total_orders, 0) AS total_orders,
    CASE 
        WHEN COALESCE(a.total_sales, 0) > 0 THEN ROUND(COALESCE(a.total_sales, 0) / NULLIF(a.total_quantity, 0), 2) 
        ELSE 0 
    END AS avg_sales_per_item
FROM 
    date_dim d
LEFT JOIN 
    AggregateSales a ON d.d_date_sk = a.ws_sold_date_sk
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    d.d_date;
