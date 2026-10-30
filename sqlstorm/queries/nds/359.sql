
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        c_total_sales.*,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales AS c_total_sales
),
TopCustomers AS (
    SELECT 
        c_customer_sk AS customer_sk,
        c_first_name,
        c_last_name,
        total_sales
    FROM 
        SalesRanked
    WHERE 
        sales_rank <= 10
)
SELECT 
    t.*, 
    (SELECT COUNT(*) FROM web_returns AS wr WHERE wr.wr_returning_customer_sk = t.customer_sk) AS total_web_returns,
    (SELECT COUNT(*) FROM store_returns AS sr WHERE sr.sr_customer_sk = t.customer_sk) AS total_store_returns
FROM 
    TopCustomers AS t
ORDER BY 
    total_sales DESC;
