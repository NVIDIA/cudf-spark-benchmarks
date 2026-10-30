
WITH ranked_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
recent_returns AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_amount) AS total_returns
    FROM 
        catalog_returns 
    WHERE 
        cr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cr_returning_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.c_first_name, 
    r.c_last_name, 
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(rr.total_returns, 0) AS total_returns,
    COALESCE(r.total_sales, 0) - COALESCE(rr.total_returns, 0) AS net_revenue,
    CASE 
        WHEN COALESCE(r.total_sales, 0) = 0 THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    ranked_sales r
LEFT JOIN 
    recent_returns rr ON r.c_customer_sk = rr.cr_returning_customer_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    net_revenue DESC;
