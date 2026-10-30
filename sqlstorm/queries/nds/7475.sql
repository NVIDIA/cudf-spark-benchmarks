
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cs.total_web_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_orders > 1
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        ss.total_store_sales,
        ss.total_store_orders,
        RANK() OVER (ORDER BY ss.total_store_sales DESC) AS store_rank
    FROM 
        StoreSales ss
    JOIN 
        store s ON ss.s_store_sk = s.s_store_sk
    WHERE 
        ss.total_store_orders > 5
)
SELECT 
    tc.full_name AS Top_Customer,
    tc.total_web_sales,
    ts.s_store_name AS Top_Store,
    ts.total_store_sales
FROM 
    TopCustomers tc
JOIN 
    TopStores ts ON tc.sales_rank = ts.store_rank
WHERE 
    tc.sales_rank <= 10 AND ts.store_rank <= 10
ORDER BY 
    tc.total_web_sales DESC, ts.total_store_sales DESC;
