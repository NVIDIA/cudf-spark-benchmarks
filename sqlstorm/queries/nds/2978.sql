WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand
    FROM 
        item
    WHERE 
        i_rec_start_date <= cast('2002-10-01' as date)
        AND (i_rec_end_date IS NULL OR i_rec_end_date > cast('2002-10-01' as date))
)
SELECT 
    d.i_item_sk,
    d.i_item_desc,
    d.i_current_price,
    d.i_brand,
    COALESCE(r.rn, 0) AS recent_return_rank,
    COALESCE(r.sr_return_quantity, 0) AS returned_quantity,
    COALESCE(a.total_sales_quantity, 0) AS sales_quantity,
    COALESCE(a.total_sales_amount, 0) AS total_sales
FROM 
    ItemDetails d
LEFT JOIN 
    RankedReturns r ON d.i_item_sk = r.sr_item_sk AND r.rn = 1
LEFT JOIN 
    AggregateSales a ON d.i_item_sk = a.ws_item_sk
WHERE 
    (COALESCE(r.sr_return_quantity, 0) > 5 OR a.total_sales_quantity > 50)
    AND d.i_current_price IS NOT NULL
ORDER BY 
    total_sales DESC, 
    i_item_desc ASC;