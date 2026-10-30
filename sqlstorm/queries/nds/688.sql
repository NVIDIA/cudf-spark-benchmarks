
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT COALESCE(ws.ws_order_number, cs.cs_order_number, ss.ss_ticket_number)) AS order_count
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
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
)
SELECT 
    rs.c_customer_sk,
    rs.c_first_name,
    rs.c_last_name,
    rs.total_sales,
    rs.order_count,
    COALESCE(ra.r_avg_sales, 0) AS avg_sales_above,
    CASE 
        WHEN rs.order_count = 0 THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status
FROM 
    RankedSales rs
LEFT JOIN (
    SELECT 
        AVG(total_sales) AS r_avg_sales 
    FROM 
        CustomerSales
) ra ON 1=1
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.total_sales DESC;
