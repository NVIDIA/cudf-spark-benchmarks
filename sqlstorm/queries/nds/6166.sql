
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY SUBSTRING(c.c_birth_country, 1, 2) ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_country
),
TopCustomers AS (
    SELECT 
        * 
    FROM 
        CustomerSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
ORDER BY 
    tc.total_sales DESC, 
    tc.order_count DESC;
