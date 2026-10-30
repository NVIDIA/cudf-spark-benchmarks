
WITH  CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 1) 
        AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 3)
    GROUP BY wr_returning_customer_sk
    HAVING SUM(wr_return_amt) IS NOT NULL
), 
AddressDetails AS (
    SELECT 
        c.c_customer_sk, 
        ca.ca_city, 
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_city DESC) AS city_rank
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales_price,
        AVG(ws_sales_price) AS avg_sales_price,
        MAX(ws_net_profit) AS max_profit
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY ws_bill_customer_sk
), 
CombinedDetails AS (
    SELECT 
        ad.c_customer_sk AS customer_sk,
        ad.ca_city,
        ad.ca_state,
        sd.total_sales_price,
        sd.avg_sales_price,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt
    FROM AddressDetails ad
    LEFT JOIN SalesDetails sd ON ad.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN CustomerReturns cr ON ad.c_customer_sk = cr.wr_returning_customer_sk
    WHERE ad.city_rank = 1
)
SELECT 
    ca_city AS city, 
    ca_state AS state, 
    COUNT(customer_sk) AS customer_count, 
    SUM(total_sales_price) AS total_sales,
    SUM(return_count) AS total_returns,
    SUM(total_return_amt) AS total_returned_amount
FROM CombinedDetails
GROUP BY ca_city, ca_state
HAVING SUM(total_sales_price) > 10000
ORDER BY ca_city, ca_state
LIMIT 10 OFFSET 10;
