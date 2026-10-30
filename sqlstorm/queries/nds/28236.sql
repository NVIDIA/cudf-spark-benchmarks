
WITH CustomerReturnCounts AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
ReturnSummary AS (
    SELECT 
        return_count,
        web_return_count,
        CASE 
            WHEN return_count > 5 THEN 'High Return'
            WHEN return_count BETWEEN 1 AND 5 THEN 'Moderate Return'
            ELSE 'No Return'
        END AS return_category
    FROM 
        CustomerReturnCounts
),
TopReturnCustomers AS (
    SELECT 
        rc.return_category, 
        COUNT(*) AS customer_count
    FROM 
        ReturnSummary rc
    GROUP BY 
        rc.return_category
)
SELECT 
    r.return_category, 
    r.customer_count,
    (SELECT COUNT(*) FROM CustomerReturnCounts) AS total_customers,
    ROUND((CAST(r.customer_count AS decimal) / (SELECT COUNT(*) FROM CustomerReturnCounts)) * 100, 2) AS percentage
FROM 
    TopReturnCustomers r
ORDER BY 
    r.customer_count DESC;
