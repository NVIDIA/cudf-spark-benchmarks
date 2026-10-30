
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rank_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
), 
TopReturns AS (
    SELECT 
        rr.sr_item_sk,
        rr.sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY rr.sr_item_sk ORDER BY rr.sr_return_quantity DESC) AS return_rank
    FROM 
        RankedReturns rr
    WHERE 
        rr.rank_return_quantity <= 10
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(cs.cs_net_profit) > 5000
), 
HistoricalReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_web_returns,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM 
        web_returns wr
    WHERE 
        wr_returned_date_sk < (SELECT MAX(wr_returned_date_sk) FROM web_returns)
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ta.sr_item_sk,
    COALESCE(ts.total_web_returns, 0) AS web_returns_count,
    cs.total_orders,
    cs.total_net_profit,
    cs.avg_sales_price,
    CASE 
        WHEN cs.total_orders IS NULL THEN 'No Orders'
        ELSE CAST(cs.total_net_profit AS STRING) || ' USD'
    END AS profit_statement
FROM 
    TopReturns ta
LEFT JOIN 
    HistoricalReturns ts ON ta.sr_item_sk = ts.wr_item_sk
LEFT JOIN 
    CustomerStats cs ON cs.c_customer_sk = (SELECT DISTINCT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL LIMIT 1)
WHERE 
    ta.return_rank = 1
ORDER BY 
    web_returns_count DESC NULLS LAST,
    cs.total_orders DESC;
