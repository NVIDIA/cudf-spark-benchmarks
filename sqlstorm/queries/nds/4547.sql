WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_web_sales IS NOT NULL
),
FrequentCustomers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(*) as freq_order_count
    FROM 
        customer c
    INNER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '1 YEAR')
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_web_sales,
    hvc.order_count,
    fc.freq_order_count,
    (CASE 
        WHEN hvc.total_web_sales > 1000 THEN 'High Roller'
        WHEN hvc.total_web_sales BETWEEN 500 AND 1000 THEN 'Mid Tier'
        ELSE 'Low Tier'
    END) AS customer_tier
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    FrequentCustomers fc ON hvc.c_customer_sk = fc.c_customer_sk
WHERE 
    hvc.sales_rank <= 100
ORDER BY 
    hvc.total_web_sales DESC;