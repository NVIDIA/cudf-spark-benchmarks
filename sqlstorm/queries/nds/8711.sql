
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 60 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_sales, 
        cs.total_transactions,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rnk
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 5000
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_transactions,
    dc.d_year,
    dc.d_month_seq,
    SUM(ws.ws_ext_sales_price) AS web_sales
FROM 
    TopCustomers tc
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = tc.c_customer_sk
LEFT JOIN 
    date_dim dc ON ws.ws_sold_date_sk = dc.d_date_sk
WHERE 
    tc.rnk <= 10
GROUP BY 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name,
    tc.total_sales,
    tc.total_transactions,
    dc.d_year,
    dc.d_month_seq
ORDER BY 
    tc.total_sales DESC, web_sales DESC;
