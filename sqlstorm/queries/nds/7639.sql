
WITH sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_demo_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458548 AND 2459144  
    GROUP BY 
        ws_bill_cdemo_sk
), customer_info AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_dep_count
    FROM 
        customer_demographics
), customer_analysis AS (
    SELECT 
        ci.cd_demo_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_dep_count,
        ss.total_net_profit,
        ss.total_orders,
        ss.avg_sales_price
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.cd_demo_sk = ss.customer_demo_sk
    WHERE 
        ci.cd_gender = 'M'  
        AND ci.cd_marital_status = 'S'  
        AND ci.cd_dep_count > 0  
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT ca.ca_address_sk) AS num_locations,
    AVG(ca.ca_gmt_offset) AS avg_gmt_offset,
    COUNT(DISTINCT ca.ca_country) AS total_countries,
    AVG(cust.total_net_profit) AS avg_total_net_profit,
    MAX(cust.total_orders) AS max_orders
FROM 
    customer_address ca
JOIN 
    customer_analysis cust ON ca.ca_address_sk = cust.cd_demo_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    avg_total_net_profit DESC
LIMIT 100;
