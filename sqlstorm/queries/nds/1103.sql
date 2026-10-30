
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk, sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        wr_web_page_sk,
        SUM(wr_return_quantity) AS total_web_returned,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, wr_item_sk, wr_web_page_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemReturns AS (
    SELECT 
        i_item_sk,
        i_product_name,
        COALESCE(SUM(cr_return_quantity), 0) AS total_catalog_returned,
        COALESCE(SUM(cr_return_amount), 0) AS total_catalog_return_amt
    FROM 
        item
    LEFT JOIN 
        catalog_returns ON item.i_item_sk = catalog_returns.cr_item_sk
    GROUP BY 
        i_item_sk, i_product_name
)
SELECT 
    cs.ws_sold_date_sk,
    cs.ws_item_sk,
    cs.total_sold,
    cs.total_net_profit,
    COALESCE(cr.total_returned, 0) AS total_store_returned,
    COALESCE(cr.total_return_amt, 0) AS total_store_return_amt,
    COALESCE(wr.total_web_returned, 0) AS total_web_returned,
    COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt,
    ir.total_catalog_returned,
    ir.total_catalog_return_amt
FROM 
    SalesData cs
LEFT JOIN 
    CustomerReturns cr ON cs.ws_sold_date_sk = cr.sr_returned_date_sk AND cs.ws_item_sk = cr.sr_item_sk
LEFT JOIN 
    WebReturns wr ON cs.ws_sold_date_sk = wr.wr_returned_date_sk AND cs.ws_item_sk = wr.wr_item_sk
LEFT JOIN 
    ItemReturns ir ON cs.ws_item_sk = ir.i_item_sk
WHERE 
    cs.total_sold > 50
    AND (cr.total_returned > 10 OR wr.total_web_returned > 5)
ORDER BY 
    cs.ws_sold_date_sk DESC, 
    cs.total_net_profit DESC
LIMIT 100;
