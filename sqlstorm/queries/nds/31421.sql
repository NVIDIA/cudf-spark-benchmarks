
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
AggregatedData AS (
    SELECT 
        i.i_item_id, 
        COALESCE(s.total_quantity, 0) AS total_sold,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(r.total_returned_amt, 0) AS total_returned_amt,
        i.i_current_price,
        (COALESCE(s.total_sales, 0) - COALESCE(r.total_returned_amt, 0)) AS net_sales_value
    FROM 
        item i
    LEFT JOIN 
        SalesCTE s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN 
        CustomerReturns r ON i.i_item_sk = r.sr_item_sk
)
SELECT 
    ad.i_item_id, 
    ad.total_sold, 
    ad.total_sales, 
    ad.total_returned_quantity,
    ad.total_returned_amt, 
    ad.i_current_price,
    ad.net_sales_value,
    CASE 
        WHEN ad.net_sales_value > 1000 THEN 'High Sales'
        WHEN ad.net_sales_value BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    AggregatedData ad
WHERE 
    ad.total_sold > 0
ORDER BY 
    ad.net_sales_value DESC
LIMIT 10;
