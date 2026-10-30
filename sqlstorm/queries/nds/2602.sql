WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2455362 AND 2455366 
    GROUP BY 
        ws_item_sk
),
ReturnsData AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns 
    WHERE 
        wr_returned_date_sk BETWEEN 2455362 AND 2455366
    GROUP BY 
        wr_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_quantity_sold, 0) AS quantity_sold,
    COALESCE(sd.total_net_profit, 0) AS net_profit,
    COALESCE(rd.total_returned_quantity, 0) AS returned_quantity,
    COALESCE(rd.total_return_amt, 0) AS return_amount,
    (COALESCE(sd.total_quantity_sold, 0) - COALESCE(rd.total_returned_quantity, 0)) AS net_sales,
    CASE 
        WHEN COALESCE(sd.total_quantity_sold, 0) = 0 THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    ReturnsData rd ON i.i_item_sk = rd.wr_item_sk
WHERE 
    i.i_current_price > (
        SELECT AVG(i_current_price) 
        FROM item 
        WHERE i_rec_start_date <= cast('2002-10-01' as date) 
        AND (i_rec_end_date IS NULL OR i_rec_end_date > cast('2002-10-01' as date))
    )
ORDER BY 
    net_sales DESC
LIMIT 10;