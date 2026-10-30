
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20.00
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_quantity, 0) AS sold_quantity,
    COALESCE(rd.total_return_quantity, 0) AS returned_quantity,
    COALESCE(sd.total_net_paid, 0) AS total_sales_amount,
    COALESCE(rd.total_return_amt, 0) AS total_return_amount,
    (COALESCE(sd.total_net_paid, 0) - COALESCE(rd.total_return_amt, 0)) AS net_revenue,
    CASE 
        WHEN COALESCE(sd.total_quantity, 0) = 0 THEN NULL
        ELSE ROUND((COALESCE(rd.total_return_quantity, 0) * 100.0) / COALESCE(sd.total_quantity, 0), 2)
    END AS return_rate_percentage
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    ReturnData rd ON i.i_item_sk = rd.wr_item_sk
WHERE 
    i.i_item_desc LIKE '%Gadget%'
ORDER BY 
    net_revenue DESC
LIMIT 100;
