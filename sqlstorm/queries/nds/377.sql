
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        ss.ss_customer_sk, 
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2021
        )
    GROUP BY 
        ss.ss_customer_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS grand_total_sales,
        ROW_NUMBER() OVER (ORDER BY (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) DESC) AS sales_rank
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.ss_customer_sk
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_web_sales,
    t.total_store_sales,
    t.grand_total_sales,
    CASE 
        WHEN t.grand_total_sales = 0 THEN 'No Sales'
        WHEN t.grand_total_sales > 1000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    TotalSales t
WHERE 
    t.grand_total_sales > 0
ORDER BY 
    t.grand_total_sales DESC
LIMIT 10;
