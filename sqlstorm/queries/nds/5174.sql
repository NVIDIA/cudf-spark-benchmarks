
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c 
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > 500
),
TopSpenders AS (
    SELECT 
        h.c_customer_sk,
        h.c_first_name,
        h.c_last_name,
        h.total_spent,
        h.total_orders
    FROM 
        HighSpenders h
    WHERE 
        h.spend_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.total_spent,
        cs.total_orders
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopSpenders cs ON c.c_customer_sk = cs.c_customer_sk
),
FinalOutput AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cd.cd_demo_sk) AS demographic_count,
        AVG(cd.total_spent) AS avg_spent,
        AVG(cd.total_orders) AS avg_orders
    FROM 
        CustomerDemographics cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    fo.cd_gender, 
    fo.cd_marital_status, 
    fo.demographic_count, 
    fo.avg_spent, 
    fo.avg_orders 
FROM 
    FinalOutput fo
ORDER BY 
    fo.demographic_count DESC, 
    fo.avg_spent DESC;
