
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS num_transactions,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rank_spent
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.num_transactions
    FROM 
        CustomerSales cs
    WHERE 
        cs.rank_spent <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        NULLIF(cd.cd_dep_college_count, 0) AS college_count,
        COALESCE(cd.cd_dep_count, 1) AS household_size
    FROM 
        customer_demographics cd
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.total_spent,
    hs.num_transactions,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    ROUND(hs.total_spent / NULLIF(cd.household_size, 0), 2) AS average_spent_per_person
FROM 
    HighSpenders hs
LEFT JOIN 
    CustomerDemographics cd ON hs.c_customer_sk = cd.cd_demo_sk
ORDER BY 
    hs.total_spent DESC;
