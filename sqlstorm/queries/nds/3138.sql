WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546 
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_ext_sales_price) AS avg_sales_price
    FROM 
        RankedSales rs
    JOIN 
        item item ON rs.ws_item_sk = item.i_item_sk
    LEFT JOIN 
        web_sales ws ON rs.ws_order_number = ws.ws_order_number
    GROUP BY 
        item.i_item_id
),
TopItems AS (
    SELECT 
        ss.i_item_id,
        ss.total_sales,
        ss.order_count,
        ss.avg_sales_price,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary ss
)
SELECT 
    ti.i_item_id,
    ti.total_sales,
    ti.order_count,
    ti.avg_sales_price,
    CASE 
        WHEN ti.sales_rank <= 10 THEN 'Top 10'
        WHEN ti.sales_rank BETWEEN 11 AND 20 THEN 'Top 20'
        ELSE 'Others'
    END AS sales_category
FROM 
    TopItems ti
WHERE 
    ti.total_sales > (
        SELECT AVG(total_sales) 
        FROM SalesSummary 
        WHERE total_sales IS NOT NULL
    )
ORDER BY 
    ti.total_sales DESC;