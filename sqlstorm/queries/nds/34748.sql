
WITH  SalesCTE AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_sales_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss_store_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(sr_ticket_number) AS returns_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesWithReturns AS (
    SELECT 
        s.ss_store_sk,
        s.total_profit,
        s.total_sales_count,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.returns_count, 0) AS returns_count
    FROM 
        SalesCTE s
    LEFT JOIN 
        CustomerReturns r ON s.ss_store_sk = r.customer_sk
)
SELECT 
    s.ss_store_sk,
    SUM(s.total_profit) AS overall_profit,
    SUM(s.total_sales_count) AS total_transaction_count,
    AVG(s.total_returns) AS average_return_amount,
    CASE 
        WHEN SUM(s.total_sales_count) > 0 THEN 
            SUM(s.total_returns) / NULLIF(SUM(s.total_sales_count), 0)
        ELSE 0 END AS return_ratio,
    COUNT(DISTINCT s.ss_store_sk) AS unique_store_count
FROM 
    SalesWithReturns s
JOIN 
    store st ON s.ss_store_sk = st.s_store_sk
WHERE 
    st.s_city LIKE '%New%' 
    AND st.s_state = 'NY'
GROUP BY 
    s.ss_store_sk
ORDER BY 
    overall_profit DESC
LIMIT 10;
