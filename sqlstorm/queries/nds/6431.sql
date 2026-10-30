
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, 
        sr_item_sk
),
WebReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        COUNT(wr_order_number) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(wr_return_tax) AS total_web_return_tax
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, 
        wr_item_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(cr.sr_returned_date_sk, wr.wr_returned_date_sk) AS return_date,
        COALESCE(cr.sr_item_sk, wr.wr_item_sk) AS item_sk,
        COALESCE(cr.total_returns, 0) + COALESCE(wr.total_web_returns, 0) AS combined_total_returns,
        COALESCE(cr.total_return_amount, 0) + COALESCE(wr.total_web_return_amount, 0) AS combined_total_return_amount,
        COALESCE(cr.total_return_tax, 0) + COALESCE(wr.total_web_return_tax, 0) AS combined_total_return_tax
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.sr_returned_date_sk = wr.wr_returned_date_sk AND cr.sr_item_sk = wr.wr_item_sk
)
SELECT 
    d.d_date AS return_date,
    COALESCE(cr.combined_total_returns, 0) AS total_returns,
    COALESCE(cr.combined_total_return_amount, 0) AS total_return_amount,
    COALESCE(cr.combined_total_return_tax, 0) AS total_tax_return,
    i.i_item_id,
    i.i_product_name
FROM 
    CombinedReturns cr
JOIN 
    date_dim d ON d.d_date_sk = cr.return_date
JOIN 
    item i ON i.i_item_sk = cr.item_sk
WHERE 
    d.d_year = 2022
ORDER BY 
    d.d_date, 
    total_returns DESC
LIMIT 100;
