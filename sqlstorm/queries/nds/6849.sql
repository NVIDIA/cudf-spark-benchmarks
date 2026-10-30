WITH CustomerPurchaseHistory AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND ws.ws_sold_date_sk BETWEEN 2459456 AND 2459496 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status 
),
TopCustomers AS (
    SELECT 
        cph.c_customer_id, 
        cph.total_spent,
        RANK() OVER (ORDER BY cph.total_spent DESC) AS spending_rank
    FROM 
        CustomerPurchaseHistory cph
)
SELECT 
    tc.c_customer_id,
    tc.total_spent
FROM 
    TopCustomers tc
WHERE 
    tc.spending_rank <= 10
ORDER BY 
    tc.total_spent DESC;