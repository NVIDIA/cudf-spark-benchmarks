
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity,
        cs.total_spent,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        d.cd_demo_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count,
        d.cd_dep_employed_count,
        d.cd_dep_college_count
    FROM 
        customer_demographics d
    WHERE 
        d.cd_credit_rating IS NOT NULL
),
AggregatedDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(cd.cd_demo_sk) AS num_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        CustomerDemographics cd
    GROUP BY 
        cd.cd_gender
)

SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_quantity,
    tc.total_spent,
    ad.cd_gender,
    ad.num_customers,
    ad.avg_purchase_estimate
FROM 
    TopCustomers tc
LEFT JOIN 
    AggregatedDemographics ad ON tc.spend_rank <= 10
WHERE 
    tc.total_orders > 3
ORDER BY 
    tc.total_spent DESC
LIMIT 10;
