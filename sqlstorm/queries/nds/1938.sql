
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),

TopCustomers AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name, 
        sr.total_sales, 
        sr.order_count,
        sr.c_customer_sk
    FROM 
        SalesRanked sr
    JOIN 
        customer c ON sr.c_customer_sk = c.c_customer_sk
    WHERE 
        sr.sales_rank <= 10
)

SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
    CASE 
        WHEN tc.total_sales > 10000 THEN 'High Value'
        WHEN tc.total_sales > 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_city IS NULL OR ca.ca_state = 'CA'
ORDER BY 
    tc.total_sales DESC
LIMIT 20;
