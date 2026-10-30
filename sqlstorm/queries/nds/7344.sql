
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Store_Sales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.web_order_count,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
),
Top_Stores AS (
    SELECT 
        ss.s_store_sk,
        ss.total_store_sales,
        ss.store_order_count,
        RANK() OVER (ORDER BY ss.total_store_sales DESC) AS sales_rank
    FROM 
        Store_Sales ss
)
SELECT 
    tc.c_customer_sk,
    ts.s_store_sk,
    tc.total_web_sales,
    ts.total_store_sales,
    tc.web_order_count,
    ts.store_order_count
FROM 
    Top_Customers tc
JOIN 
    Top_Stores ts ON tc.sales_rank = ts.sales_rank
WHERE 
    tc.sales_rank <= 10;
