
WITH CustomerRevenue AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(*) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
TopCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.total_revenue,
        cr.total_orders,
        ROW_NUMBER() OVER (ORDER BY cr.total_revenue DESC) AS revenue_rank
    FROM 
        CustomerRevenue cr
    WHERE 
        cr.total_revenue IS NOT NULL
)
SELECT 
    tc.c_customer_sk,
    tc.total_revenue,
    tc.total_orders,
    tc.revenue_rank,
    DENSE_RANK() OVER (PARTITION BY tc.revenue_rank ORDER BY tc.total_orders DESC) AS order_rank,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    tc.revenue_rank <= 10
    AND NOT EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = tc.c_customer_sk 
        AND ss.ss_net_paid > 1000
    )
ORDER BY 
    tc.revenue_rank, tc.total_orders DESC;
