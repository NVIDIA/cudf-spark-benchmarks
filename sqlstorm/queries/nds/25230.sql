
WITH AddressInfo AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
        ca_city,
        ca_state,
        SUM(CASE WHEN ss_sales_price > 100 THEN ss_sales_price ELSE 0 END) AS high_value_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c_first_name, c_last_name, ca_city, ca_state
),
RegionStats AS (
    SELECT 
        ca_state,
        AVG(high_value_sales) AS avg_high_value_sales,
        SUM(total_transactions) AS total_transactions
    FROM 
        AddressInfo
    GROUP BY 
        ca_state
)
SELECT 
    ca_state,
    avg_high_value_sales,
    total_transactions,
    CONCAT('State: ', ca_state, ' | Avg High Sales: $', ROUND(avg_high_value_sales, 2), ' | Total Transactions: ', total_transactions) AS summary
FROM 
    RegionStats
ORDER BY 
    avg_high_value_sales DESC
LIMIT 10;
