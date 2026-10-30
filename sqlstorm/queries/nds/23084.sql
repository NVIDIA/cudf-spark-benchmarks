
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rank <= 10
),
SalesStats AS (
    SELECT 
        cs.customer_id,
        AVG(cs.total_sales) AS avg_sales,
        MAX(cs.total_sales) AS max_sales,
        MIN(cs.total_sales) AS min_sales
    FROM 
        TopCustomers cs
    GROUP BY 
        cs.customer_id
),
Returns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_returns,
        COUNT(cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
FinalStats AS (
    SELECT 
        t.customer_id,
        s.avg_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        s.max_sales,
        s.min_sales,
        (s.avg_sales - COALESCE(r.total_returns, 0)) AS net_sales
    FROM 
        SalesStats s
    JOIN 
        TopCustomers t ON s.customer_id = t.customer_id
    LEFT JOIN 
        Returns r ON t.customer_id = r.cr_returning_customer_sk
)
SELECT 
    f.customer_id,
    f.avg_sales,
    f.max_sales,
    f.min_sales,
    f.total_returns,
    f.net_sales
FROM 
    FinalStats f
WHERE 
    f.net_sales > 0
ORDER BY 
    f.net_sales DESC;
