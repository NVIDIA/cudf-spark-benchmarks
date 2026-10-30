
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        total_spent,
        total_orders,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM 
        CustomerSales
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        tc.total_spent
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        TopCustomers tc ON c.c_customer_sk = tc.c_customer_sk
)
SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status, 
    COUNT(*) AS count_customers, 
    AVG(tc.total_spent) AS avg_spent
FROM 
    CustomerDemographics cd
JOIN 
    TopCustomers tc ON cd.cd_demo_sk = tc.c_customer_sk
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    count_customers DESC;
