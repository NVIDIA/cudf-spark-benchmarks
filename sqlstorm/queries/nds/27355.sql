
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY c.c_last_name, c.c_first_name) AS name_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
TopCustomers AS (
    SELECT 
        full_name,
        ca_city,
        name_rank,
        c_customer_sk
    FROM 
        RankedCustomers
    WHERE 
        name_rank <= 10
),
PurchaseStats AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    tc.full_name,
    tc.ca_city,
    ps.total_sales,
    ps.order_count
FROM 
    TopCustomers tc
JOIN 
    PurchaseStats ps ON tc.c_customer_sk = ps.c_customer_sk
ORDER BY 
    tc.ca_city, ps.total_sales DESC;
