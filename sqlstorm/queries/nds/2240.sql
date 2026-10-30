
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) as sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        cs.total_orders,
        ss.total_tickets
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.s_store_sk
)
SELECT 
    ts.c_customer_sk,
    ts.c_first_name,
    ts.c_last_name,
    ts.total_web_sales,
    ts.total_store_sales,
    ts.total_orders,
    ts.total_tickets,
    CASE 
        WHEN ts.total_web_sales > ts.total_store_sales THEN 'More Online Sales'
        WHEN ts.total_web_sales < ts.total_store_sales THEN 'More In-Store Sales'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM 
    TotalSales ts
WHERE 
    (ts.total_web_sales + ts.total_store_sales) > 0
ORDER BY 
    ts.total_web_sales DESC, 
    ts.total_store_sales DESC
LIMIT 10;
