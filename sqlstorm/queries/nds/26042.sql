
WITH AddressCity AS (
    SELECT 
        ca_city,
        COUNT(*) AS city_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        SUM(cd_dep_count) AS total_dependencies,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
CustomerWithAddress AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        aa.ca_city,
        aa.ca_state,
        da.d_date,
        da.d_month_seq,
        da.d_year
    FROM 
        customer c
    JOIN 
        customer_address aa ON c.c_current_addr_sk = aa.ca_address_sk
    JOIN 
        date_dim da ON c.c_first_sales_date_sk = da.d_date_sk
)
SELECT 
    cwa.ca_city,
    cwa.ca_state,
    COUNT(cwa.c_customer_sk) AS customer_count,
    COALESCE(ac.city_count, 0) AS city_count,
    ds.total_customers,
    ds.total_dependencies,
    ds.avg_purchase_estimate
FROM 
    CustomerWithAddress cwa
LEFT JOIN 
    AddressCity ac ON cwa.ca_city = ac.ca_city
LEFT JOIN 
    DemographicStats ds ON cwa.ca_state = ds.cd_gender
GROUP BY 
    cwa.ca_city, cwa.ca_state, ac.city_count, ds.total_customers, ds.total_dependencies, ds.avg_purchase_estimate
ORDER BY 
    customer_count DESC, cwa.ca_city;
