WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
AllReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY SUM(wr_return_amt_inc_tax) DESC) AS return_rank
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
ActiveItems AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price
    FROM 
        item
    WHERE 
        i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i_rec_end_date IS NULL OR i_rec_end_date > cast('2002-10-01' as date))
),
SalesSummary AS (
    SELECT 
        a.i_item_sk,
        a.i_product_name,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_returned, 0) AS total_returned,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        (COALESCE(s.total_sales, 0) - COALESCE(r.total_return_amt, 0)) AS net_sales
    FROM 
        ActiveItems a
    LEFT JOIN 
        SalesCTE s ON a.i_item_sk = s.ws_item_sk
    LEFT JOIN 
        AllReturns r ON a.i_item_sk = r.wr_item_sk
)
SELECT 
    ss.i_item_sk,
    ss.i_product_name,
    ss.total_quantity,
    ss.total_sales,
    ss.total_returned,
    ss.total_return_amt,
    ss.net_sales,
    CASE 
        WHEN ss.net_sales > 0 THEN 'Profitable'
        WHEN ss.net_sales < 0 THEN 'Loss'
        ELSE 'Break-even'
    END AS sales_status
FROM 
    SalesSummary ss
WHERE 
    ss.total_quantity > 0 
ORDER BY 
    ss.net_sales DESC
LIMIT 10;