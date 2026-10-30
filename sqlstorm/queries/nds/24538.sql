
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk AS customer_sk, 
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_ship_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
SalesComparison AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(w.total_web_sales, 0) AS total_web_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        CASE 
            WHEN COALESCE(w.total_web_sales, 0) > COALESCE(r.total_returns, 0) THEN 'Web Sales Greater'
            WHEN COALESCE(w.total_web_sales, 0) < COALESCE(r.total_returns, 0) THEN 'Returns Greater'
            ELSE 'Equal'
        END AS sales_comparison,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        r.return_count
    FROM 
        customer c
    LEFT JOIN 
        WebSalesSummary w ON c.c_customer_sk = w.customer_sk
    LEFT JOIN 
        CustomerReturns r ON c.c_customer_sk = r.customer_sk
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        DENSE_RANK() OVER (PARTITION BY sales_comparison ORDER BY total_returns DESC) AS return_rank
    FROM 
        SalesComparison
)
SELECT 
    c.full_name,
    c.total_web_sales,
    c.total_returns,
    c.sales_comparison,
    c.web_sales_rank,
    c.return_rank,
    CASE 
        WHEN c.return_count IS NULL THEN 'No returns registered'
        ELSE CAST(c.return_count AS STRING)
    END AS return_registration_status
FROM 
    RankedCustomers c
WHERE 
    c.sales_comparison = 'Returns Greater'
    OR (c.total_web_sales > 1000 AND c.return_rank <= 10)
ORDER BY 
    c.web_sales_rank, c.return_rank;
