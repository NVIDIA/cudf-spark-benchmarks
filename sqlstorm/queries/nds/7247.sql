
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
        MAX(CASE WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_sold_date_sk ELSE ws.ws_sold_date_sk END) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.store_transactions,
        cs.web_transactions,
        cs.last_purchase_date,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_sales > 0
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.store_transactions,
    tc.web_transactions,
    MAX(dd.d_date) AS recent_purchase_date
FROM 
    TopCustomers tc
INNER JOIN 
    date_dim dd ON dd.d_date_sk = tc.last_purchase_date
WHERE 
    tc.sales_rank <= 100
GROUP BY 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.store_transactions,
    tc.web_transactions
ORDER BY 
    tc.total_sales DESC;
