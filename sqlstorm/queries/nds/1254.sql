
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount,
        SUM(cr_return_tax) AS total_returned_tax
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
CombinedMetrics AS (
    SELECT 
        c.c_customer_id,
        coalesce(cr.total_returned_quantity, 0) AS total_returned_quantity,
        coalesce(cr.total_returned_amount, 0) AS total_returned_amount,
        coalesce(cr.total_returned_tax, 0) AS total_returned_tax,
        ws.total_net_profit,
        ws.total_orders,
        ws.avg_net_paid
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        WebSalesSummary ws ON c.c_customer_sk = ws.ws_ship_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_orders > 0 THEN total_net_profit / NULLIF(total_orders, 0)
        ELSE 0
    END AS avg_profit_per_order,
    CASE 
        WHEN total_returned_quantity > 0 THEN total_returned_amount / NULLIF(total_returned_quantity, 0)
        ELSE 0
    END AS avg_return_amount_per_item
FROM 
    CombinedMetrics
WHERE 
    (total_returned_quantity > 5 OR total_net_profit > 1000.00)
ORDER BY 
    total_net_profit DESC, c_customer_id
LIMIT 100;
