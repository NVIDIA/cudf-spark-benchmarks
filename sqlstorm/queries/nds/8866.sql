
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND
        d.d_month_seq IN (1, 2, 3)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        tc.total_orders,
        tc.total_spent,
        tc.rank
    FROM 
        TopCustomers tc
    JOIN 
        customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
    WHERE 
        tc.rank <= 10
)

SELECT 
    cd.cd_gender,
    COUNT(*) AS count_customers,
    AVG(cd.total_spent) AS avg_spent,
    AVG(cd.total_orders) AS avg_orders
FROM 
    CustomerDemographics cd
GROUP BY 
    cd.cd_gender
ORDER BY 
    count_customers DESC
