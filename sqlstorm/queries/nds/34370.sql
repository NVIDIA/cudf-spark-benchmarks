
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighestSales AS (
    SELECT 
        ws_item_sk,
        total_sales,
        total_orders
    FROM 
        SalesCTE
    WHERE 
        sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ReturnMetrics AS (
    SELECT 
        hs.ws_item_sk,
        hs.total_sales,
        cr.total_returns,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        (COALESCE(cr.total_returns, 0) * 1.0 / NULLIF(hs.total_orders, 0)) * 100 AS return_rate_percentage
    FROM 
        HighestSales hs
    LEFT JOIN 
        CustomerReturns cr ON hs.ws_item_sk = cr.sr_item_sk
)
SELECT 
    hm.ws_item_sk,
    hm.total_sales,
    hm.total_returns,
    hm.total_returned_amt,
    hm.return_rate_percentage,
    COALESCE(hm.total_sales, 0) - COALESCE(hm.total_returned_amt, 0) AS net_sales
FROM 
    ReturnMetrics hm
JOIN 
    item i ON hm.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer))
WHERE 
    i.i_current_price > 50
ORDER BY 
    hm.return_rate_percentage DESC;
