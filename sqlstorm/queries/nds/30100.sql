
WITH  SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        ws_sold_date_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
), AddressedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT sc.ss_ticket_number) AS total_sales,
        SUM(sc.ss_net_paid) AS total_revenue
    FROM 
        customer c
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN store_sales sc ON c.c_customer_sk = sc.ss_customer_sk
    WHERE 
        ca.ca_state IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
), EnhancedSales AS (
    SELECT 
        ac.c_customer_sk,
        ac.c_first_name,
        ac.c_last_name,
        ac.ca_city,
        ac.ca_state,
        ac.total_sales,
        ac.total_revenue,
        sc.rnk
    FROM 
        AddressedCustomers ac
        JOIN SalesCTE sc ON ac.c_customer_sk = sc.ws_bill_customer_sk
    WHERE 
        sc.rnk = 1
)
SELECT 
    e.c_customer_sk,
    e.c_first_name,
    e.c_last_name,
    e.ca_city,
    e.ca_state,
    COALESCE(e.total_sales, 0) AS total_sales,
    COALESCE(e.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN e.total_revenue > 1000 THEN 'High Value'
        WHEN e.total_revenue BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM 
    EnhancedSales e
FULL OUTER JOIN customer_demographics cd ON e.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' OR cd.cd_gender IS NULL
ORDER BY 
    e.total_revenue DESC
LIMIT 100;
