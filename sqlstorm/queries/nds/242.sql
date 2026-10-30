
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid + cs.cs_net_paid + ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cs.sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_web_sales, 0) AS total_web_sales,
    COALESCE(tc.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(tc.total_store_sales, 0) AS total_store_sales,
    (COALESCE(tc.total_web_sales, 0) + COALESCE(tc.total_catalog_sales, 0) + COALESCE(tc.total_store_sales, 0)) AS grand_total_sales,
    RANK() OVER (ORDER BY (COALESCE(tc.total_web_sales, 0) + COALESCE(tc.total_catalog_sales, 0) + COALESCE(tc.total_store_sales, 0)) DESC) AS overall_rank
FROM 
    TopCustomers tc
ORDER BY 
    grand_total_sales DESC;
