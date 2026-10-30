
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
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
        cs.total_sales IS NOT NULL
),
RecentActivity AS (
    SELECT 
        c.c_customer_sk,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    hs.total_sales,
    hs.order_count,
    ra.last_purchase_date,
    CASE 
        WHEN ra.last_purchase_date IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    HighSpenders hs
LEFT JOIN 
    RecentActivity ra ON hs.c_customer_sk = ra.c_customer_sk
WHERE 
    hs.sales_rank <= 10
ORDER BY 
    hs.total_sales DESC;
