
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS state_rank
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        cs.total_orders
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
)
SELECT 
    DISTINCT hvc.c_customer_sk,
    hvc.total_spent,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    hvc.ca_city,
    hvc.ca_state
FROM 
    HighValueCustomers hvc
WHERE 
    hvc.cd_marital_status IS NOT NULL
    AND hvc.cd_gender IN ('M', 'F')
    AND hvc.total_orders > (
        SELECT 
            AVG(total_orders) 
        FROM 
            CustomerSales
    )
ORDER BY 
    hvc.total_spent DESC
LIMIT 100;
