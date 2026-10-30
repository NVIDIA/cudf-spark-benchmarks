
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
FrequentCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales AS cs
    WHERE 
        cs.total_orders > 3
),
RecentReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns AS wr
    WHERE 
        wr.wr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    fc.total_sales,
    fc.total_orders,
    COALESCE(rr.total_returned, 0) AS total_returned,
    COALESCE(rr.return_count, 0) AS return_count
FROM 
    FrequentCustomers AS fc
LEFT JOIN 
    RecentReturns AS rr ON fc.c_customer_sk = rr.wr_returning_customer_sk
ORDER BY 
    fc.sales_rank
LIMIT 10;
