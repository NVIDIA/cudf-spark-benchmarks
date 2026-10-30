
WITH  sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
return_summary AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
combined AS (
    SELECT 
        ss.c_customer_sk,
        ss.c_first_name,
        ss.c_last_name,
        ss.total_quantity,
        ss.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN rs.total_returns IS NOT NULL THEN 
                (ss.total_sales / NULLIF(rs.total_return_amount, 0))
            ELSE 
                ss.total_sales
        END AS adjusted_sales
    FROM 
        sales_summary ss
    LEFT JOIN 
        return_summary rs ON ss.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.total_sales,
    c.total_returns,
    c.adjusted_sales,
    CASE 
        WHEN c.adjusted_sales > 1000 THEN 'High'
        WHEN c.adjusted_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    combined c
WHERE 
    c.adjusted_sales IS NOT NULL
ORDER BY 
    c.total_sales DESC
LIMIT 100;
