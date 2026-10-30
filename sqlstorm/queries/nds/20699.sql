
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopReturnedItems AS (
    SELECT 
        rr.sr_item_sk,
        rr.total_returned_quantity,
        rr.total_returned_amount,
        COUNT(DISTINCT sr_store_sk) AS unique_stores
    FROM 
        RankedReturns rr
    JOIN 
        store_returns sr ON rr.sr_item_sk = sr.sr_item_sk
    WHERE 
        rr.rank <= 10
    GROUP BY 
        rr.sr_item_sk, rr.total_returned_quantity, rr.total_returned_amount
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        ws_item_sk
),
FinalSelection AS (
    SELECT 
        t.i_item_sk AS item_id, 
        COALESCE(tr.total_returned_quantity, 0) AS returned_quantity,
        COALESCE(tr.total_returned_amount, 0) AS returned_amount,
        COALESCE(sd.total_sales_quantity, 0) AS sales_quantity,
        COALESCE(sd.total_sales_amount, 0) AS sales_amount
    FROM 
        item t
    LEFT JOIN 
        TopReturnedItems tr ON t.i_item_sk = tr.sr_item_sk
    LEFT JOIN 
        SalesData sd ON t.i_item_sk = sd.ws_item_sk
)
SELECT 
    item_id,
    returned_quantity,
    sales_quantity,
    CASE 
        WHEN returned_quantity > sales_quantity THEN 'Returns exceed sales'
        WHEN returned_quantity = sales_quantity THEN 'Returns equal sales'
        ELSE 'Sales exceed returns'
    END AS return_sales_analysis,
    'N/A' AS additional_info
FROM 
    FinalSelection
WHERE 
    (returned_quantity IS NOT NULL OR sales_quantity IS NOT NULL)
    AND (returned_amount IS NOT NULL OR sales_amount IS NOT NULL)
ORDER BY 
    returned_quantity DESC,
    sales_quantity ASC;
