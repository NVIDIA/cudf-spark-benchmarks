
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
StoreSales AS (
    SELECT 
        ss.ss_store_sk, 
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
),
SalesComparison AS (
    SELECT 
        tc.c_customer_id, 
        tc.total_sales, 
        ts.total_store_sales, 
        CASE 
            WHEN tc.total_sales > ts.total_store_sales THEN 'Customer'
            WHEN tc.total_sales < ts.total_store_sales THEN 'Store'
            ELSE 'Equal'
        END AS relationship
    FROM 
        TopCustomers tc
    JOIN 
        StoreSales ts ON tc.sales_rank <= 10
)
SELECT 
    relationship, 
    COUNT(*) AS count
FROM 
    SalesComparison
GROUP BY 
    relationship
ORDER BY 
    count DESC;
