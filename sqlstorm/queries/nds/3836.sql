
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
StoreSales AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_sales_transactions,
        SUM(ss_sales_price) AS total_sales_amt
    FROM store_sales
    GROUP BY ss_store_sk
),
RevenueRanked AS (
    SELECT 
        ss.ss_store_sk,
        ss.total_sales_amt,
        RANK() OVER (ORDER BY ss.total_sales_amt DESC) AS sales_rank
    FROM StoreSales ss
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COALESCE(sr.total_returned_quantity, 0) AS total_returns,
    COALESCE(sr.total_returned_amt, 0) AS total_returned_amt,
    s.total_sales_transactions,
    s.total_sales_amt,
    CASE 
        WHEN sr.total_returned_quantity IS NULL THEN 'No Returns'
        WHEN sr.total_returned_quantity > s.total_sales_transactions THEN 'High Return Rate'
        ELSE 'Normal Return Rate'
    END AS return_status
FROM customer_address ca
LEFT JOIN CustomerReturns sr ON sr.sr_customer_sk = ca.ca_address_sk
JOIN RevenueRanked r ON r.ss_store_sk = sr.sr_customer_sk
JOIN StoreSales s ON s.ss_store_sk = r.ss_store_sk
WHERE ca.ca_state IN ('CA', 'NY') 
  AND s.total_sales_amt > 1000.00
  AND s.total_sales_transactions > 5
ORDER BY ca.ca_city, total_returned_amt DESC;
