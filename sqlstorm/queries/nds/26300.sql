
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
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
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS employed_dependents,
        SUM(cd_dep_college_count) AS college_dependents
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),

SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)

SELECT 
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.total_dependents,
    s.d_year,
    s.total_sales,
    s.total_orders
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.address_count > 100
JOIN 
    SalesStats s ON s.total_orders > 50
ORDER BY 
    a.ca_state, c.cd_gender, s.d_year;
