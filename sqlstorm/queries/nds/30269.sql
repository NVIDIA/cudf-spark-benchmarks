
WITH  CustomerCTE AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name,
        c_birth_year, 
        ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY c_birth_year DESC) AS rn
    FROM customer 
    JOIN customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
    WHERE c_birth_year IS NOT NULL 
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
ReturnSummary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales WHERE ws_bill_customer_sk IS NOT NULL)
    GROUP BY sr_customer_sk
)
SELECT 
    ccte.c_first_name,
    ccte.c_last_name,
    ccte.ca_city,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_return_amount, 0)) AS net_sales,
    CASE 
        WHEN ss.order_count > 0 THEN ROUND((COALESCE(rs.total_return_amount, 0) * 100.0 / ss.total_sales), 2)
        ELSE NULL 
    END AS return_percentage
FROM CustomerCTE ccte
LEFT JOIN SalesSummary ss ON ccte.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN ReturnSummary rs ON ccte.c_customer_sk = rs.sr_customer_sk
WHERE ccte.rn = 1
ORDER BY net_sales DESC
LIMIT 10;
