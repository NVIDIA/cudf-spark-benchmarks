
WITH CustomerInfo AS (
    SELECT 
        C.c_first_name,
        C.c_last_name,
        CA.ca_city,
        CA.ca_state,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status,
        CD.cd_purchase_estimate,
        HD.hd_buy_potential,
        CONCAT(C.c_first_name, ' ', C.c_last_name) AS full_name,
        CASE 
            WHEN CD.cd_marital_status = 'M' THEN 'Married' 
            WHEN CD.cd_marital_status = 'S' THEN 'Single' 
            ELSE 'Other' 
        END AS marital_status_desc,
        C.c_customer_sk  -- Added to ensure proper join
    FROM 
        customer C
    JOIN 
        customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
    JOIN 
        customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN 
        household_demographics HD ON CD.cd_demo_sk = HD.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        CI.full_name,
        CI.ca_city,
        CI.ca_state,
        SUM(SS.ss_net_paid) AS total_spending,
        COUNT(DISTINCT SS.ss_ticket_number) AS purchase_count
    FROM 
        store_sales SS
    JOIN 
        CustomerInfo CI ON SS.ss_customer_sk = CI.c_customer_sk
    GROUP BY 
        CI.full_name, CI.ca_city, CI.ca_state
)
SELECT 
    ca_city AS city,
    ca_state AS state,
    COUNT(*) AS customer_count,
    AVG(total_spending) AS avg_spending,
    MAX(purchase_count) AS max_purchase_count,
    MIN(purchase_count) AS min_purchase_count
FROM 
    SalesSummary
GROUP BY 
    ca_city, ca_state
ORDER BY 
    ca_city, ca_state;
