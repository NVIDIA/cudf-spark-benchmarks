
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_address_count,
        COUNT(ca_street_number) AS street_number_count,
        COUNT(ca_suite_number) AS suite_number_count
    FROM 
        customer_address
    WHERE 
        ca_street_name IS NOT NULL
    GROUP BY 
        ca_city
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesPerformance AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity_sold,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    ac.ca_city,
    ac.unique_address_count,
    ac.street_number_count,
    ac.suite_number_count,
    cs.cd_gender,
    cs.customer_count,
    cs.total_dependents,
    cs.avg_purchase_estimate,
    sp.d_year,
    sp.total_net_profit,
    sp.total_quantity_sold,
    sp.avg_sales_price
FROM 
    AddressCounts ac
JOIN 
    CustomerStats cs ON cs.customer_count > 100
JOIN 
    SalesPerformance sp ON sp.total_net_profit > 1000
ORDER BY 
    ac.ca_city, cs.cd_gender, sp.d_year DESC;
