
WITH address AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS city_state_zip,
        ca.ca_country
    FROM 
        customer_address ca
), demographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_count) AS total_dependencies
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
), sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MIN(ws.ws_sold_date_sk) AS first_purchase_date_sk,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    addr.full_address,
    addr.city_state_zip,
    addr.ca_country,
    dem.customer_count,
    dem.avg_purchase_estimate,
    dem.total_dependencies,
    s.total_sales,
    s.total_net_profit,
    d.d_date AS purchase_day,
    d.d_day_name AS purchase_day_name
FROM 
    address addr
LEFT JOIN 
    customer c ON addr.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    demographics dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
LEFT JOIN 
    sales s ON c.c_customer_sk = s.ws_bill_customer_sk
JOIN 
    date_dim d ON s.first_purchase_date_sk = d.d_date_sk
WHERE 
    addr.ca_country = 'USA' 
    AND dem.avg_purchase_estimate > 1000
ORDER BY 
    s.total_sales DESC, dem.total_dependencies ASC;
