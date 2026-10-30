
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_by_gender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.avg_order_value,
        cs.cd_gender,
        cs.rank_by_gender
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_orders > 1 AND cs.rank_by_gender <= 5
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returned,
        COUNT(*) AS count_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalStats AS (
    SELECT 
        tc.c_customer_sk,
        tc.total_orders,
        tc.total_spent,
        tc.avg_order_value,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(rs.count_returns, 0) AS count_returns,
        (tc.total_spent - COALESCE(rs.total_returned, 0)) AS net_spent
    FROM 
        TopCustomers tc
    LEFT JOIN 
        ReturnStats rs ON tc.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.total_orders,
    f.total_spent,
    f.avg_order_value,
    f.total_returned,
    f.count_returns,
    f.net_spent
FROM 
    FinalStats f
ORDER BY 
    f.net_spent DESC;
