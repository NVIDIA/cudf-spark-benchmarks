
WITH  customer_return_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_returned,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(COALESCE(sr.sr_return_amt, 0)) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
total_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_ranking AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(t.sales_amount, 0) AS total_sales,
        csr.total_returned,
        csr.total_return_amt,
        CASE 
            WHEN COALESCE(t.sales_amount, 0) = 0 THEN NULL
            ELSE ROUND((csr.total_return_amt / NULLIF(t.sales_amount, 0)) * 100, 2)
        END AS return_percentage,
        csr.rn
    FROM 
        customer c
    LEFT JOIN 
        total_sales t ON c.c_customer_sk = t.ws_bill_customer_sk
    LEFT JOIN 
        customer_return_summary csr ON c.c_customer_sk = csr.c_customer_sk
)
SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.total_sales,
    cr.total_returned,
    cr.total_return_amt,
    cr.return_percentage
FROM 
    customer_ranking cr
WHERE 
    cr.rn <= 10
ORDER BY 
    cr.return_percentage DESC;
