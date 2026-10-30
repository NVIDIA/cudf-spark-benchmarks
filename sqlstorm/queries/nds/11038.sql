
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales_per_customer,
        AVG(sales_count) AS avg_sales_count_per_customer
    FROM 
        customer_sales
),
high_sales_customers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_sales
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > (SELECT avg_sales_per_customer FROM avg_sales)
)

SELECT 
    h.c_customer_sk,
    h.total_sales,
    a.avg_sales_per_customer,
    a.avg_sales_count_per_customer
FROM 
    high_sales_customers h,
    avg_sales a;
