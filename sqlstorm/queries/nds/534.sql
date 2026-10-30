WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, 
        cd.cd_gender, cd.cd_marital_status, 
        cd.cd_education_status, cd.cd_purchase_estimate, 
        cd.cd_credit_rating, cd.cd_dep_count, 
        cd.cd_dep_employed_count, cd.cd_dep_college_count
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSummary cs
    WHERE 
        cs.total_profit > 1000
),
RecentTransactions AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS recent_orders_count,
        SUM(ws.ws_net_profit) AS recent_total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_date >= cast('2002-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_profit,
    hvc.total_orders,
    COALESCE(rt.recent_orders_count, 0) AS recent_orders_count,
    COALESCE(rt.recent_total_profit, 0) AS recent_total_profit,
    CASE 
        WHEN hvc.profit_rank <= 10 THEN 'Top Performer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RecentTransactions rt ON hvc.c_customer_sk = rt.ws_bill_customer_sk
ORDER BY 
    hvc.total_profit DESC, hvc.total_orders DESC;