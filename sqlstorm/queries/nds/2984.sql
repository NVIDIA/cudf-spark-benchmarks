
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
), 
StoreSalesData AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_paid) AS total_sales, 
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 20230101 AND 20230930 
    GROUP BY 
        ss_store_sk
)
SELECT 
    s.s_store_name,
    COALESCE(cs.total_sales, 0) AS total_store_sales,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    cs.total_transactions,
    CASE 
        WHEN cs.total_transactions > 0 
        THEN (COALESCE(cr.total_return_quantity, 0) / cs.total_transactions) * 100 
        ELSE 0 
    END AS return_rate
FROM 
    store s
LEFT JOIN 
    StoreSalesData cs ON s.s_store_sk = cs.ss_store_sk
LEFT JOIN 
    CustomerReturns cr ON cr.wr_returning_customer_sk = s.s_store_sk
WHERE 
    s.s_state = 'CA'
ORDER BY 
    return_rate DESC
LIMIT 10;
