
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS order_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM 
        SalesData
    GROUP BY 
        ws_item_sk
),
HighPerformingItems AS (
    SELECT 
        item.i_item_id,
        ts.total_sales,
        ts.order_count,
        ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        item
    JOIN 
        TotalSales ts ON item.i_item_sk = ts.ws_item_sk
    WHERE 
        ts.total_sales > 1000
)
SELECT 
    hpi.i_item_id,
    hpi.total_sales,
    hpi.order_count,
    COALESCE(NULLIF(hpi.order_count, 0), 1) AS safe_order_count,
    CAST(hpi.total_sales / NULLIF(hpi.order_count, 0) AS DECIMAL(10, 2)) AS average_sales_per_order,
    CASE 
        WHEN hpi.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM 
    HighPerformingItems hpi
WHERE 
    hpi.sales_rank <= 100
ORDER BY 
    hpi.total_sales DESC;

