
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as rnk,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) as total_sales_price
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
),
SalesByReason AS (
    SELECT 
        cr_reason_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns 
    GROUP BY 
        cr_reason_sk
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS num_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalStats AS (
    SELECT 
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_sales_price,
        r.ws_net_profit,
        COALESCE(b.total_returns, 0) AS total_returns,
        COALESCE(b.total_return_amount, 0) AS total_return_amount,
        COALESCE(re.num_returns, 0) AS num_store_returns,
        COALESCE(re.total_returned_amount, 0) AS total_store_returned_amount
    FROM 
        RankedSales AS r
    LEFT JOIN 
        SalesByReason AS b ON r.ws_item_sk = b.cr_reason_sk 
    LEFT JOIN 
        ReturnStats AS re ON r.ws_item_sk = re.sr_item_sk
    WHERE 
        r.rnk = 1
)
SELECT 
    f.ws_item_sk,
    f.ws_quantity,
    f.ws_sales_price,
    f.ws_net_profit,
    f.total_returns,
    f.total_return_amount,
    f.num_store_returns,
    f.total_store_returned_amount,
    CASE 
        WHEN f.num_store_returns > 0 THEN 'Returns Detected'
        ELSE 'No Returns'
    END AS return_status
FROM 
    FinalStats AS f
WHERE 
    f.ws_net_profit IS NOT NULL OR f.total_store_returned_amount > 100
ORDER BY 
    f.ws_net_profit DESC, 
    f.total_store_returned_amount ASC
LIMIT 20 OFFSET 10;
