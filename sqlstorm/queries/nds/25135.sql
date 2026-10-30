
WITH AddressSummary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(CASE 
            WHEN ca_county LIKE '%County%' THEN 1 
            ELSE 0 
        END) AS county_mentions
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerGenderSummary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
PromoActivity AS (
    SELECT 
        p_promo_name,
        COUNT(DISTINCT ws_order_number) AS promotion_sales_count,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    JOIN 
        promotion ON ws_promo_sk = p_promo_sk
    GROUP BY 
        p_promo_name
),
FinalBenchmark AS (
    SELECT 
        A.ca_city,
        A.ca_state,
        A.unique_addresses,
        A.avg_street_name_length,
        A.county_mentions,
        G.cd_gender,
        G.total_customers,
        G.avg_purchase_estimate,
        P.promotion_sales_count,
        P.total_net_profit
    FROM 
        AddressSummary A
    LEFT JOIN 
        CustomerGenderSummary G ON 1=1
    LEFT JOIN 
        PromoActivity P ON 1=1
)
SELECT 
    ca_city,
    ca_state,
    unique_addresses,
    avg_street_name_length,
    county_mentions,
    cd_gender,
    total_customers,
    avg_purchase_estimate,
    promotion_sales_count,
    total_net_profit
FROM 
    FinalBenchmark
ORDER BY 
    ca_city, ca_state;
