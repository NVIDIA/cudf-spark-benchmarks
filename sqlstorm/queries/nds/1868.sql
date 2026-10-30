
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS customer_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sd.total_net_paid, 0) AS total_net_sales,
    COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rd.total_returned_amt, 0) AS total_returned_amt,
    (COALESCE(sd.total_net_paid, 0) - COALESCE(rd.total_returned_amt, 0)) AS net_profit_after_returns,
    (COALESCE(sd.total_quantity, 0) - COALESCE(rd.total_returned_quantity, 0)) AS net_units_sold
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    ReturnData rd ON i.i_item_sk = rd.wr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    net_profit_after_returns DESC
LIMIT 10;
