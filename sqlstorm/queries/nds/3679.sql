
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), RankedSales AS (
    SELECT 
        cs.*,
        ROW_NUMBER() OVER (PARTITION BY CASE 
            WHEN total_sales BETWEEN 0 AND 100 THEN 'Low'
            WHEN total_sales BETWEEN 101 AND 500 THEN 'Medium'
            ELSE 'High'
        END ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
), TopCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_sales,
        cr.order_count
    FROM 
        RankedSales cr
    WHERE 
        cr.sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    (SELECT 
        COUNT(*) 
     FROM 
        store s 
     LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk 
     WHERE 
        ss.ss_customer_sk = tc.c_customer_sk) AS store_visit_count,
    (SELECT 
        AVG(ws.ws_net_profit) 
     FROM 
        web_sales ws 
     WHERE 
        ws.ws_bill_customer_sk = tc.c_customer_sk) AS average_web_profit
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC, 
    tc.order_count DESC;
