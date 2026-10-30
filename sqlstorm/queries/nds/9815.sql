
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq BETWEEN 1 AND 6 
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_order_number
),

ReturnData AS (
    SELECT 
        wr.wr_item_sk, 
        SUM(wr.wr_return_quantity) AS total_returned_quantity, 
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_month_seq BETWEEN 1 AND 6 
    GROUP BY 
        wr.wr_item_sk
),

FinalReport AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity,
        sd.total_sales_amount,
        (sd.total_sales_amount - COALESCE(rd.total_returned_amount, 0)) AS net_sales_amount
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    fr.total_quantity_sold,
    fr.total_returned_quantity,
    fr.net_sales_amount,
    CASE 
        WHEN fr.net_sales_amount > 10000 THEN 'High Performer'
        WHEN fr.net_sales_amount BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer' 
    END AS performance_category
FROM 
    FinalReport fr
JOIN 
    item i ON fr.ws_item_sk = i.i_item_sk
ORDER BY 
    net_sales_amount DESC
LIMIT 10;
