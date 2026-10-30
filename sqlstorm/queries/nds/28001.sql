
WITH CustomerLocation AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(DISTINCT c_customer_sk) AS customer_count 
    FROM 
        customer_address 
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk 
    GROUP BY 
        ca_city, ca_state
), CustomerDemographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(DISTINCT c_customer_sk) AS demographic_count 
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk 
    GROUP BY 
        cd_gender, cd_marital_status
), SalesData AS (
    SELECT 
        d_year, 
        SUM(ws_net_profit) AS total_profit 
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk 
    GROUP BY 
        d_year
), TopCities AS (
    SELECT 
        ca_city, ca_state, customer_count 
    FROM 
        CustomerLocation 
    ORDER BY 
        customer_count DESC 
    LIMIT 10
)

SELECT 
    t.d_year, 
    t.total_profit, 
    c.ca_city, 
    c.ca_state, 
    d.cd_gender, 
    d.cd_marital_status, 
    d.demographic_count 
FROM 
    SalesData t 
JOIN 
    TopCities c ON c.customer_count > 0 
JOIN 
    CustomerDemographics d ON d.demographic_count > 0 
ORDER BY 
    t.d_year, c.ca_city;
