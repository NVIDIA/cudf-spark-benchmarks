
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM 
        item i
)
SELECT 
    ii.i_item_desc,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_net_paid, 0) AS total_net_paid,
    CASE 
        WHEN COALESCE(sd.total_quantity, 0) = 0 THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status,
    DENSE_RANK() OVER (ORDER BY COALESCE(sd.total_net_paid, 0) DESC) AS sales_rank
FROM 
    ItemInfo ii
LEFT JOIN 
    SalesData sd ON ii.i_item_sk = sd.ws_item_sk
WHERE 
    ii.i_current_price > 10.00
    AND (sd.total_net_paid IS NULL OR sd.total_net_paid > 100.00)
ORDER BY 
    sales_rank
LIMIT 50;
