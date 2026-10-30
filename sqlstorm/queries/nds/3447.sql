
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItemSales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        p.p_promo_id,
        p.p_promo_name
    FROM 
        RankedSales r
    LEFT JOIN 
        promotion p ON r.total_sales > p.p_cost AND r.sales_rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(t.total_quantity, 0) AS total_quantity_sold,
    COALESCE(t.total_sales, 0) AS total_sales_amount,
    COALESCE(r.total_returned, 0) AS total_returns,
    COALESCE(r.total_return_amt, 0) AS total_return_value,
    (COALESCE(t.total_sales, 0) - COALESCE(r.total_return_amt, 0)) AS net_sales,
    CASE 
        WHEN r.total_returned IS NULL THEN 'No Returns'
        WHEN r.total_returned > 0 THEN 'Returned'
        ELSE 'Sold'
    END AS return_status
FROM 
    item i
LEFT JOIN 
    TopItemSales t ON i.i_item_sk = t.ws_item_sk
LEFT JOIN 
    CustomerReturns r ON i.i_item_sk = r.sr_item_sk
WHERE 
    i.i_current_price > 20.00
AND 
    (t.total_sales IS NULL OR t.total_sales > 1000.00)
ORDER BY 
    net_sales DESC
LIMIT 100;
