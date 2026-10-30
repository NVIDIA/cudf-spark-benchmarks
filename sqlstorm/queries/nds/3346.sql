
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_item_sk) AS distinct_items_returned
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
Sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 0
    GROUP BY 
        ws_bill_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.distinct_items_returned, 0) AS distinct_items_returned,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        COALESCE(s.unique_orders, 0) AS unique_orders
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        Sales s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_returned,
    cs.distinct_items_returned,
    cs.total_net_profit,
    cs.unique_orders,
    CASE 
        WHEN cs.total_net_profit > 1000 THEN 'High Profit'
        WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    CASE 
        WHEN cs.total_returned > 10 THEN 'Frequent Returns'
        ELSE 'Rare Returns'
    END AS return_category
FROM 
    CustomerStats cs
WHERE 
    cs.total_returned IS NOT NULL OR cs.total_net_profit IS NOT NULL
ORDER BY 
    cs.total_net_profit DESC, 
    cs.total_returned ASC;
