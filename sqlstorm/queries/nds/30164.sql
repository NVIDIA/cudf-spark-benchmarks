WITH  CustomerCTE AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_year,
        c_current_addr_sk,
        CAST(c_first_name AS VARCHAR(100)) || ' ' || CAST(c_last_name AS VARCHAR(100)) AS full_name,
        ROW_NUMBER() OVER (PARTITION BY c_birth_year ORDER BY c_last_name) AS rn
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit
    FROM web_sales
    WHERE ws_sold_date_sk > 0
    GROUP BY ws_bill_customer_sk
),
AddressDetails AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk DESC) AS addr_rank
    FROM customer_address
)
SELECT 
    c.full_name,
    c.c_birth_year,
    a.ca_city,
    a.ca_state,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count,
    COALESCE(ss.avg_profit, 0) AS avg_profit,
    a.addr_rank
FROM CustomerCTE c
LEFT JOIN AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    a.addr_rank = 1 OR c.c_birth_year < 1980
ORDER BY 
    total_sales DESC, 
    c.c_birth_year ASC;