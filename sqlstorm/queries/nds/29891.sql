WITH demographic_analysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c.c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_credit_rating = 'High' THEN 1 ELSE 0 END) AS high_credit_count,
        SUM(CASE WHEN cd_credit_rating = 'Medium' THEN 1 ELSE 0 END) AS medium_credit_count,
        SUM(CASE WHEN cd_credit_rating = 'Low' THEN 1 ELSE 0 END) AS low_credit_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
location_analysis AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca_state
),
warehouse_analysis AS (
    SELECT 
        w.w_country,
        COUNT(DISTINCT ws.ws_warehouse_sk) AS total_warehouses,
        SUM(ws.ws_quantity) AS total_items_sold
    FROM 
        warehouse AS w
    JOIN 
        web_sales AS ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_country
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.cd_education_status,
    da.total_customers,
    da.avg_purchase_estimate,
    la.ca_state,
    la.customer_count AS state_customer_count,
    la.total_net_profit,
    wa.w_country,
    wa.total_warehouses,
    wa.total_items_sold
FROM 
    demographic_analysis AS da
JOIN 
    location_analysis AS la ON da.cd_gender = 'F'  
JOIN 
    warehouse_analysis AS wa ON la.customer_count > 100  
ORDER BY 
    da.total_customers DESC, la.total_net_profit DESC;