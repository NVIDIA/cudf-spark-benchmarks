
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS grand_total_sales
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
),
CustomerRankedSales AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY c.grand_total_sales DESC) AS sales_rank
    FROM 
        TotalSales c
    WHERE 
        c.grand_total_sales > 0
)
SELECT 
    crs.c_first_name,
    crs.c_last_name,
    crs.grand_total_sales,
    crs.sales_rank,
    CASE 
        WHEN crs.sales_rank <= 10 THEN 'Top 10 Customers'
        WHEN crs.sales_rank <= 25 THEN 'Next 15 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM 
    CustomerRankedSales crs
ORDER BY 
    crs.sales_rank;
