
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count
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
    tc.total_sales,
    COALESCE(sr.total_return_amt, 0) AS total_return_amt,
    COALESCE(cr.total_catalog_return_amt, 0) AS total_catalog_return_amt,
    (tc.total_sales - COALESCE(sr.total_return_amt, 0) - COALESCE(cr.total_catalog_return_amt, 0)) AS net_sales
FROM 
    TopCustomers tc
LEFT JOIN (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
) sr ON sr.wr_returning_customer_sk = tc.c_customer_sk
LEFT JOIN (
    SELECT 
        cr_returning_cdemo_sk,
        SUM(cr_return_amount) AS total_catalog_return_amt
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_cdemo_sk
) cr ON cr.cr_returning_cdemo_sk = tc.c_customer_sk
WHERE 
    tc.total_sales IS NOT NULL
ORDER BY 
    net_sales DESC;
