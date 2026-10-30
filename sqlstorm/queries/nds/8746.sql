
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        d.d_year
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.d_year,
        RANK() OVER (PARTITION BY cs.d_year ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales AS cs
)
SELECT 
    d_year AS YEAR,
    c_first_name,
    c_last_name,
    total_sales,
    order_count
FROM 
    TopCustomers
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, sales_rank;
