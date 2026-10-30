
WITH Address_Frequency AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
Demographics_Summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS total_customers,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
Website_Statistics AS (
    SELECT 
        w.web_name,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales AS ws
    JOIN 
        web_site AS w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        w.web_name
),
Combined_Statistics AS (
    SELECT 
        a.ca_city,
        d.cd_gender,
        d.cd_marital_status,
        d.total_customers,
        d.total_dependents,
        w.web_name,
        w.total_orders,
        w.total_profit
    FROM 
        Address_Frequency a
    JOIN 
        Demographics_Summary d ON a.address_count > 100
    JOIN 
        Website_Statistics w ON w.total_orders > 50
)
SELECT 
    ca_city,
    cd_gender,
    cd_marital_status,
    total_customers,
    total_dependents,
    web_name,
    total_orders,
    total_profit,
    CONCAT('City: ', ca_city, ', Gender: ', cd_gender, ', Marital Status: ', cd_marital_status) AS demographic_summary,
    CONCAT('Web: ', web_name, ', Orders: ', total_orders, ', Profit: $', ROUND(total_profit, 2)) AS web_summary
FROM 
    Combined_Statistics
ORDER BY 
    total_profit DESC, total_orders DESC;
