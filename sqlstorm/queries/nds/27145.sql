
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FrequentShoppers AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        COUNT(*) AS purchase_count
    FROM 
        CustomerInfo ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.full_name, ci.ca_city, ci.ca_state
    HAVING 
        COUNT(*) > 5
),
CityStatistics AS (
    SELECT 
        ca.ca_city,
        COUNT(*) AS total_customers,
        COUNT(DISTINCT ci.c_customer_sk) AS distinct_frequent_shoppers
    FROM 
        CustomerInfo ci
    JOIN 
        customer_address ca ON ci.c_customer_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
)
SELECT 
    cs.ca_city,
    cs.total_customers,
    cs.distinct_frequent_shoppers,
    ROUND((CAST(cs.distinct_frequent_shoppers AS DECIMAL) / NULLIF(cs.total_customers, 0)) * 100, 2) AS frequent_shopper_percentage
FROM 
    CityStatistics cs
ORDER BY 
    frequent_shopper_percentage DESC
LIMIT 10;
