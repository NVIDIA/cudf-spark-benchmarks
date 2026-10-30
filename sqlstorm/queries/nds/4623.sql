
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

HighValueCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cs.total_spent,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent IS NOT NULL AND cs.total_spent > 1000
),

CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)

SELECT 
    hvc.customer_id, 
    hvc.total_spent, 
    hvc.total_orders, 
    cd.cd_gender, 
    cd.cd_marital_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = hvc.customer_id
WHERE 
    hvc.sales_rank <= 10
ORDER BY 
    hvc.total_spent DESC
