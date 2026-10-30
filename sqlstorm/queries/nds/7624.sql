
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, 
        sr_item_sk
), 
TopItems AS (
    SELECT 
        rr.sr_item_sk,
        i.i_item_id,
        i.i_item_desc,
        rr.total_return_amt,
        rr.total_return_quantity,
        RANK() OVER (ORDER BY rr.total_return_amt DESC) AS rnk
    FROM 
        RankedReturns rr
    JOIN 
        item i ON rr.sr_item_sk = i.i_item_sk
    WHERE 
        rr.total_return_amt > 0
), 
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_amt,
        SUM(ws_quantity) AS total_sales_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
FinalReport AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        ti.total_return_amt,
        ti.total_return_quantity,
        sd.total_sales_amt,
        sd.total_sales_quantity,
        (COALESCE(sd.total_sales_amt, 0) -ti.total_return_amt) AS net_profit
    FROM 
        TopItems ti
    LEFT JOIN 
        SalesData sd ON ti.sr_item_sk = sd.ws_item_sk
    WHERE 
        ti.rnk <= 10
)

SELECT 
    *
FROM 
    FinalReport
ORDER BY 
    total_return_amt DESC;
