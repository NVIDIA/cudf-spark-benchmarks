
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TopCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerStats
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.total_orders,
    tc.total_sales,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10 in Gender'
        ELSE 'Below Top 10'
    END AS rank_description
FROM 
    TopCustomers tc
WHERE 
    tc.total_orders > (
        SELECT 
            AVG(total_orders) 
        FROM 
            CustomerStats
    )
ORDER BY 
    tc.cd_gender, tc.total_sales DESC
LIMIT 100;
