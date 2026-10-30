
WITH ranked_sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_quantity) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss_store_sk
),
top_stores AS (
    SELECT 
        r.ss_store_sk,
        r.total_quantity,
        r.total_sales,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM 
        ranked_sales r
    JOIN 
        store s ON r.ss_store_sk = s.s_store_sk
    WHERE 
        r.sales_rank <= 5
),
customer_returns AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        sr_store_sk
),
final_report AS (
    SELECT 
        ts.ss_store_sk,
        ts.s_store_name,
        ts.s_city,
        ts.s_state,
        ts.total_quantity,
        ts.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        top_stores ts
    LEFT JOIN 
        customer_returns cr ON ts.ss_store_sk = cr.sr_store_sk
)
SELECT 
    *,
    (total_sales - total_return_amount) AS net_sales
FROM 
    final_report
ORDER BY 
    total_sales DESC;
