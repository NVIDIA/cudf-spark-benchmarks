
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_purchase_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_purchase_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.store_purchase_count,
        cs.web_purchase_count,
        RANK() OVER (ORDER BY cs.total_store_sales + cs.total_web_sales DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_store_sales,
    tc.total_web_sales,
    tc.store_purchase_count,
    tc.web_purchase_count
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 100
ORDER BY 
    tc.total_store_sales + tc.total_web_sales DESC;
