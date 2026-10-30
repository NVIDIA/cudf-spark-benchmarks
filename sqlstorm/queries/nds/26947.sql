
WITH address_count AS (
    SELECT 
        ca_city,
        COUNT(*) AS total_addresses,
        SUM(CASE WHEN ca_state = 'CA' THEN 1 ELSE 0 END) AS ca_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
demographics_gender AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_quantity) AS total_units_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
combined_info AS (
    SELECT 
        a.ca_city,
        a.total_addresses,
        a.ca_addresses,
        d.cd_gender,
        d.total_customers,
        d.avg_purchase_estimate,
        s.total_profit,
        s.total_units_sold
    FROM 
        address_count a
    JOIN 
        demographics_gender d ON d.total_customers > 50
    LEFT JOIN 
        sales_summary s ON s.ws_bill_customer_sk = d.total_customers
)

SELECT 
    ca_city,
    total_addresses,
    ca_addresses,
    cd_gender,
    total_customers,
    avg_purchase_estimate,
    total_profit,
    total_units_sold
FROM 
    combined_info
WHERE 
    total_profit > 1000 AND total_units_sold > 500
ORDER BY 
    total_profit DESC, total_units_sold DESC;
