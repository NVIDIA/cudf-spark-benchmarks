
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id, 
        cs.total_sales,
        cs.total_transactions,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
YearlySaleStats AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.total_transactions,
    yss.total_profit,
    yss.avg_net_paid,
    CASE 
        WHEN hvc.total_sales IS NULL THEN 'Not Available'
        WHEN hvc.total_sales > 5000 THEN 'High Spender'
        ELSE 'Regular Spender'
    END AS customer_category
FROM 
    HighValueCustomers hvc
FULL OUTER JOIN YearlySaleStats yss ON hvc.sales_rank <= 10
WHERE 
    (hvc.total_transactions > 5 OR yss.total_profit > 10000)
ORDER BY 
    hvc.total_sales DESC NULLS LAST;
