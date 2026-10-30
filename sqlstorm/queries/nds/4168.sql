
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_ship_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(r.total_return_quantity, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(s.total_orders, 0) AS total_orders,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        COALESCE(s.avg_sales_price, 0) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        RankedReturns r ON c.c_customer_sk = r.sr_customer_sk
    LEFT JOIN 
        SalesSummary s ON c.c_customer_sk = s.ws_ship_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_returns,
    cs.total_return_amount,
    cs.total_orders,
    cs.total_net_profit,
    cs.avg_sales_price,
    CASE 
        WHEN cs.total_net_profit > 1000 THEN 'High Value'
        WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CustomerStats cs
WHERE 
    cs.total_returns > 0
ORDER BY 
    cs.total_net_profit DESC
LIMIT 100;
