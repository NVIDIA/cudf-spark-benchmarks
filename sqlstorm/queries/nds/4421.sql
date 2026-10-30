
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS sale_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
),
SalesRanked AS (
    SELECT 
        c.*,
        DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        c.total_sales,
        CASE 
            WHEN c.total_sales > 1000 THEN 'Gold'
            WHEN c.total_sales BETWEEN 500 AND 1000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM 
        SalesRanked c
    WHERE 
        c.sales_rank <= 100
)
SELECT 
    h.c_customer_sk,
    h.c_first_name,
    h.c_last_name,
    h.total_sales,
    h.customer_tier,
    CASE 
        WHEN h.total_sales IS NULL THEN 'No Sales'
        ELSE CONCAT('Total Sales: $', h.total_sales)
    END AS sales_info
FROM 
    HighValueCustomers h
LEFT JOIN 
    customer_address ca ON h.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IS NOT NULL
ORDER BY 
    h.total_sales DESC;
