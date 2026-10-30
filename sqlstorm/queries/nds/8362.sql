WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        i.i_item_desc,
        ri.total_sales,
        ri.order_count
    FROM 
        RankedSales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.sales_rank <= 10
)
SELECT 
    ti.i_item_desc,
    ti.total_sales,
    ti.order_count,
    CASE 
        WHEN ti.total_sales >= 10000 THEN 'High Performer'
        WHEN ti.total_sales >= 5000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    TopItems ti
ORDER BY 
    ti.total_sales DESC;