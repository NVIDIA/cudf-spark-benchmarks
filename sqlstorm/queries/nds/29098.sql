
WITH enriched_customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city AS city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        (CASE 
            WHEN cd.cd_dep_count > 0 THEN 'Has Dependents' 
            ELSE 'No Dependents' 
         END) AS dependent_status,
        (SELECT AVG(cs.cs_net_profit) 
         FROM catalog_sales cs
         WHERE cs.cs_bill_customer_sk = c.c_customer_sk) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND ca.ca_state = 'CA'
),
sales_analysis AS (
    SELECT 
        city,
        COUNT(*) AS total_customers,
        AVG(avg_net_profit) AS avg_net_profit
    FROM 
        enriched_customer_data
    GROUP BY 
        city
)
SELECT 
    city,
    total_customers,
    avg_net_profit,
    RANK() OVER (ORDER BY avg_net_profit DESC) AS profit_rank,
    CASE 
        WHEN avg_net_profit > 1000 THEN 'High Value Market'
        WHEN avg_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value Market'
        ELSE 'Low Value Market'
    END AS market_segment
FROM 
    sales_analysis
ORDER BY 
    profit_rank;
