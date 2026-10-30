
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id, full_name, ca.ca_city
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    full_name,
    ca_city,
    total_sales
FROM 
    TopCustomers
WHERE 
    sales_rank <= 5
ORDER BY 
    ca_city, total_sales DESC;
