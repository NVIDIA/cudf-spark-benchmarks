
WITH Address_City AS (
    SELECT DISTINCT
        ca_city,
        ca_state,
        COUNT(ca_address_sk) AS address_count
    FROM customer_address
    GROUP BY ca_city, ca_state
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(cd_demo_sk) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
Time_Stats AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(CASE WHEN d_current_month = 'Y' THEN 1 ELSE 0 END) AS current_month_sales,
        SUM(CASE WHEN d_current_year = 'Y' THEN 1 ELSE 0 END) AS current_year_sales
    FROM date_dim
    GROUP BY d_year, d_month_seq
)
SELECT 
    ac.ca_city,
    ac.ca_state,
    ac.address_count,
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count,
    ts.d_year,
    ts.d_month_seq,
    ts.current_month_sales,
    ts.current_year_sales
FROM Address_City ac
JOIN Demographics d ON ac.address_count > d.demographic_count
JOIN Time_Stats ts ON ts.current_month_sales > 0
ORDER BY ac.ca_state, ac.ca_city, d.cd_gender, d.cd_marital_status, ts.d_year DESC, ts.d_month_seq DESC;
