
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent_per_order,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IS NOT NULL
        AND cd.cd_marital_status IN ('M', 'S')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
Spendings AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.avg_spent_per_order,
        cs.spending_rank,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'High'
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS spending_category
    FROM 
        CustomerSummary cs
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.avg_spent_per_order,
        cs.spending_category
    FROM 
        Spendings cs
    WHERE 
        cs.spending_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.total_orders,
    tc.total_spent,
    tc.avg_spent_per_order,
    tc.spending_category,
    COALESCE((
        SELECT COUNT(DISTINCT wr_item_sk) 
        FROM web_returns wr 
        WHERE wr_returning_customer_sk = tc.c_customer_sk
    ), 0) AS items_returned,
    COALESCE((
        SELECT SUM(wr_return_amt) 
        FROM web_returns wr 
        WHERE wr_returning_customer_sk = tc.c_customer_sk
    ), 0) AS total_return_amount
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_spent DESC;
