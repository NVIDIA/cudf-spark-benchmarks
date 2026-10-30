WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependent_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk 
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk 
    GROUP BY 
        d_year
),
Promotions AS (
    SELECT 
        p_channel_details,
        COUNT(DISTINCT p_promo_id) AS total_promotions,
        AVG(p_cost) AS avg_cost
    FROM 
        promotion
    GROUP BY 
        p_channel_details
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.avg_street_name_length,
    a.max_street_name_length,
    a.min_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.avg_dependent_count,
    c.total_purchase_estimate,
    s.d_year,
    s.total_sales,
    s.total_profit,
    p.p_channel_details,
    p.total_promotions,
    p.avg_cost
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.ca_state = 'CA'  
JOIN 
    SalesStats s ON s.d_year = 2001  
JOIN 
    Promotions p ON p.total_promotions > 10  
ORDER BY 
    a.unique_addresses DESC, 
    c.total_customers DESC;