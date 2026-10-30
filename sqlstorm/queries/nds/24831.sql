
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_customer_sk,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS return_rank
    FROM store_returns
    WHERE sr_return_quantity > 0
),
AggregateReturns AS (
    SELECT 
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_return_quantity,
        SUM(rr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT rr.sr_customer_sk) AS unique_customers
    FROM RankedReturns rr
    WHERE rr.return_rank <= 5
    GROUP BY rr.sr_item_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_price,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
FinalAnalysis AS (
    SELECT 
        COALESCE(ar.sr_item_sk, ss.ws_item_sk) AS item_sk,
        COALESCE(ar.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(ar.total_return_amt, 0) AS total_return_amt,
        COALESCE(ss.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(ss.total_sales_price, 0) AS total_sales_price,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        CASE 
            WHEN COALESCE(ss.total_sales_quantity, 0) = 0 THEN 'No Sales'
            ELSE 
                CASE 
                    WHEN COALESCE(ar.total_return_quantity, 0) > COALESCE(ss.total_sales_quantity, 0) THEN 'Too Many Returns'
                    ELSE 'Healthy Sales'
                END 
        END AS sales_health
    FROM AggregateReturns ar
    FULL OUTER JOIN SalesSummary ss ON ar.sr_item_sk = ss.ws_item_sk
)
SELECT 
    fa.item_sk,
    fa.total_return_quantity,
    fa.total_return_amt,
    fa.total_sales_quantity,
    fa.total_sales_price,
    fa.total_net_profit,
    fa.sales_health
FROM FinalAnalysis fa
WHERE 
    (fa.total_return_quantity > 100 OR fa.total_sales_quantity < 50)
    AND (fa.sales_health = 'Too Many Returns' OR fa.sales_health = 'No Sales')
ORDER BY fa.total_return_quantity DESC, fa.total_sales_quantity ASC;
