WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
AverageSales AS (
    SELECT 
        ws_item_sk, 
        AVG(total_sales_amount) AS avg_sales
    FROM 
        SalesData
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(a.avg_sales, 0) AS average_sales,
    sd.total_quantity_sold,
    RANK() OVER (ORDER BY COALESCE(a.avg_sales, 0) DESC) as sales_rank
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    AverageSales a ON i.i_item_sk = a.ws_item_sk
WHERE 
    i.i_current_price IS NOT NULL AND 
    (i.i_item_desc LIKE '%premium%' OR i.i_item_desc LIKE '%luxury%')
ORDER BY 
    sales_rank, average_sales DESC
LIMIT 10;