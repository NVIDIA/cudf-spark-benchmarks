
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_web_page_sk) AS web_page_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT *,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM CustomerSales
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.web_page_count,
    COALESCE(cd.cd_gender, 'UNKNOWN') AS gender,
    CASE 
        WHEN tc.total_sales > 10000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    CASE 
        WHEN tc.web_page_count IS NULL THEN 'No Pages Visited'
        ELSE 'Pages Visited: ' || tc.web_page_count
    END AS page_visit_status
FROM 
    TopCustomers tc
LEFT JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
