
WITH address_analysis AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS distinct_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        SUM(LENGTH(ca_street_name)) AS total_street_name_length,
        SUM(LENGTH(ca_street_type)) AS total_street_type_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
gender_analysis AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_analysis AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    aa.ca_state,
    aa.total_addresses,
    aa.distinct_cities,
    aa.avg_street_name_length,
    ga.cd_gender,
    ga.total_customers,
    ga.avg_dependents,
    sa.d_year,
    sa.total_net_profit,
    sa.total_orders,
    sa.total_quantity_sold
FROM 
    address_analysis aa
JOIN 
    gender_analysis ga ON aa.total_addresses > (SELECT AVG(total_addresses) FROM address_analysis)
JOIN 
    sales_analysis sa ON sa.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_analysis)
ORDER BY 
    aa.ca_state, ga.cd_gender, sa.d_year;
