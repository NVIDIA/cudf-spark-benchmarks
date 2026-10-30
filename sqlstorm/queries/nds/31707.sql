
WITH  SalesHierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rn
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
AverageCustomerReturn AS (
    SELECT 
        AVG(total_return_amount) AS avg_return_amt,
        AVG(total_return_quantity) AS avg_return_qty
    FROM 
        CustomerReturns
),
ActiveStores AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        s_state 
    FROM 
        store 
    WHERE 
        s_closed_date_sk IS NULL
)
SELECT 
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    COALESCE(h.total_profit, 0) AS total_profit,
    COALESCE(h.total_sales, 0) AS total_sales,
    CASE 
        WHEN h.total_profit > a.avg_return_amt THEN 'High Profit'
        ELSE 'Normal Profit'
    END AS profit_category,
    CASE 
        WHEN r.total_return_quantity IS NULL THEN 'No Returns'
        ELSE 'Returns Present'
    END AS return_status
FROM 
    ActiveStores s
LEFT JOIN 
    SalesHierarchy h ON s.s_store_sk = h.ss_store_sk AND h.rn = 1
LEFT JOIN 
    CustomerReturns r ON r.sr_customer_sk IN (
        SELECT DISTINCT ws_bill_customer_sk 
        FROM web_sales
    )
CROSS JOIN 
    AverageCustomerReturn a
ORDER BY 
    total_profit DESC,
    s.s_store_name;
