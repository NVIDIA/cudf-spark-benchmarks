
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 
        AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_orders
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        FilteredSales
)
SELECT 
    i.i_item_id,
    fs.total_sales,
    fs.total_orders,
    CASE 
        WHEN fs.total_sales > (SELECT avg_sales FROM AverageSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_category,
    COALESCE(
        (SELECT 
            COUNT(*) 
        FROM 
            store_sales ss 
        WHERE 
            ss.ss_item_sk = fs.ws_item_sk 
            AND ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)),
        0
    ) AS total_store_sales
FROM 
    FilteredSales fs
JOIN 
    item i ON fs.ws_item_sk = i.i_item_sk
ORDER BY 
    fs.total_sales DESC;
