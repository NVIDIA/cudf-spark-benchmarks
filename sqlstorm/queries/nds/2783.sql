
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > 1000
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
), 
FinalData AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hvc.total_orders,
        hvc.total_spent
    FROM 
        HighValueCustomers hvc
    JOIN 
        customer c ON hvc.c_customer_sk = c.c_customer_sk
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    fd.c_first_name,
    fd.c_last_name,
    COALESCE(fd.cd_gender, 'Unknown') AS gender,
    COALESCE(fd.cd_marital_status, 'Unknown') AS marital_status,
    fd.total_orders,
    fd.total_spent,
    CASE 
        WHEN fd.total_spent > 5000 THEN 'Platinum'
        WHEN fd.total_spent > 2000 THEN 'Gold'
        ELSE 'Silver'
    END AS customer_tier
FROM 
    FinalData fd
ORDER BY 
    fd.total_spent DESC
LIMIT 10;
