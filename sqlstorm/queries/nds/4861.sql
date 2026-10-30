
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS total_orders_returned
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebSalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
StoreSalesStats AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_orders
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss_customer_sk
)

SELECT 
    c.c_customer_id,
    COALESCE(cr.total_orders_returned, 0) AS total_returns,
    COALESCE(ws.total_orders, 0) AS total_web_orders,
    COALESCE(ss.total_orders, 0) AS total_store_orders,
    (COALESCE(cr.total_return_amount, 0) / NULLIF(ws.total_net_profit, 0)) * 100 AS return_percentage_of_web_sales,
    (COALESCE(cr.total_return_amount, 0) / NULLIF(ss.total_net_profit, 0)) * 100 AS return_percentage_of_store_sales
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    WebSalesStats ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    StoreSalesStats ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    c.c_birth_year < 1990 
ORDER BY 
    return_percentage_of_web_sales DESC, return_percentage_of_store_sales DESC
LIMIT 100;
