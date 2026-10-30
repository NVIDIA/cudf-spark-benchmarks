
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    d.d_date,
    CASE 
        WHEN COALESCE(r.r_reason_desc, '') = '' THEN 'No Reason'
        ELSE r.r_reason_desc
    END AS return_reason
FROM 
    TopCustomers t
JOIN 
    store_returns sr ON t.c_customer_sk = sr.sr_customer_sk
JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN 
    date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE 
    t.rank <= 10 
    AND d.d_year = 2023 
    AND t.total_sales > 1000 
UNION 
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    d.d_date,
    'No Return' AS return_reason
FROM 
    TopCustomers t
LEFT JOIN 
    store_returns sr ON t.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE 
    t.rank <= 10 
    AND d.d_year = 2023 
    AND sr.sr_customer_sk IS NULL;
