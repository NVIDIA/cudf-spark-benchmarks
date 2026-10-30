
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
WebSalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_web_quantity,
        SUM(ws_net_profit) AS total_web_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
StoreSalesData AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_quantity) AS total_store_quantity,
        SUM(ss_net_profit) AS total_store_profit
    FROM store_sales
    GROUP BY ss_customer_sk
),
SalesComparison AS (
    SELECT 
        cus.c_customer_id,
        COALESCE(CR.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(WS.total_web_quantity, 0) AS total_web_quantity,
        COALESCE(ST.total_store_quantity, 0) AS total_store_quantity,
        (COALESCE(WS.total_web_profit, 0) + COALESCE(ST.total_store_profit, 0)) AS total_combined_profit
    FROM customer cus
    LEFT JOIN CustomerReturns CR ON cus.c_customer_sk = CR.cr_returning_customer_sk
    LEFT JOIN WebSalesData WS ON cus.c_customer_sk = WS.ws_bill_customer_sk
    LEFT JOIN StoreSalesData ST ON cus.c_customer_sk = ST.ss_customer_sk
)
SELECT 
    s.c_customer_id,
    s.total_return_quantity,
    s.total_web_quantity,
    s.total_store_quantity,
    CASE 
        WHEN s.total_web_quantity > s.total_store_quantity THEN 'Web Sales Dominant'
        WHEN s.total_store_quantity > s.total_web_quantity THEN 'Store Sales Dominant'
        ELSE 'Equal Sales'
    END AS sales_preference,
    s.total_combined_profit
FROM SalesComparison s
ORDER BY s.total_combined_profit DESC
LIMIT 100;
