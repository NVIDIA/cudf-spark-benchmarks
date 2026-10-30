WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_paid_inc_tax) AS avg_spent_per_order,
        cd.cd_gender,
        cd.cd_marital_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.avg_spent_per_order,
        cs.cd_gender,
        cs.cd_marital_status
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.spending_rank <= 5
),
RecentReturns AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = (cast('2002-10-01' as date) - INTERVAL '30 days'))
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.total_orders,
    tc.total_spent,
    tc.avg_spent_per_order,
    COALESCE(rr.total_returned, 0) AS total_returned,
    rr.return_count
FROM 
    TopCustomers tc
LEFT JOIN 
    RecentReturns rr ON tc.c_customer_sk = rr.sr_customer_sk
ORDER BY 
    tc.total_spent DESC;