
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_customer_sk,
        SUM(ss_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales 
    GROUP BY 
        ss_store_sk, ss_customer_sk
), 
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        a.ca_city,
        a.ca_state,
        COALESCE(a.ca_country, 'Unknown') AS ca_country
    FROM 
        customer c
    LEFT JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
), 
TopCustomers AS (
    SELECT 
        rs.ss_store_sk, 
        rs.ss_customer_sk, 
        rs.total_sales, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country
    FROM 
        RankedSales rs
    JOIN 
        CustomerAddresses ca ON rs.ss_customer_sk = ca.c_customer_sk
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    s.s_store_name,
    tc.ca_city,
    tc.ca_state,
    SUM(tc.total_sales) AS top_sales_total,
    COUNT(*) AS number_of_top_customers,
    CASE 
        WHEN SUM(tc.total_sales) IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    TopCustomers tc
JOIN 
    store s ON tc.ss_store_sk = s.s_store_sk
GROUP BY 
    s.s_store_name, 
    tc.ca_city, 
    tc.ca_state
HAVING 
    SUM(tc.total_sales) > 1000
ORDER BY 
    s.s_store_name ASC, 
    number_of_top_customers DESC;
