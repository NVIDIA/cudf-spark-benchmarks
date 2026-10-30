
WITH  SalesTrend AS (
    SELECT 
        d.d_date AS sale_date,
        SUM(ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS sales_rank
    FROM 
        date_dim d
    LEFT JOIN 
        store_sales s ON d.d_date_sk = s.ss_sold_date_sk
    GROUP BY 
        d.d_date
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesAndReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_returns, 0) AS total_returns
    FROM 
        customer c
    LEFT JOIN (
        SELECT 
            ss_customer_sk,
            SUM(ss_ext_sales_price) AS total_sales
        FROM 
            store_sales
        GROUP BY 
            ss_customer_sk
    ) s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN CustomerReturns r ON c.c_customer_sk = r.cr_returning_customer_sk
),
SalesRank AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        AVG(total_sales) OVER () AS avg_sales
    FROM 
        SalesAndReturns
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM SalesAndReturns)
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    s.total_return_amount,
    s.total_returns,
    CASE 
        WHEN s.total_sales > s.avg_sales THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    SalesRank s
WHERE 
    s.sales_rank <= 100
ORDER BY 
    s.total_sales DESC;
