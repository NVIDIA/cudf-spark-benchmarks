
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
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
RankedCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_sales, 
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
FilteredCustomers AS (
    SELECT 
        rc.*, 
        CASE 
            WHEN rc.total_sales IS NULL THEN 'No Sales'
            WHEN rc.order_count = 0 THEN 'No Orders'
            ELSE 'Active'
        END AS status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.order_count > 1
)
SELECT 
    fc.c_customer_sk, 
    CONCAT(fc.c_first_name, ' ', fc.c_last_name) AS full_name, 
    COALESCE(fc.total_sales, 0) AS total_sales,
    fc.sales_rank,
    fc.status
FROM 
    FilteredCustomers fc
ORDER BY 
    fc.sales_rank ASC
LIMIT 10;
