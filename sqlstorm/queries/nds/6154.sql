
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk
), demographic_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
)

SELECT 
    ci.c_customer_sk,
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status,
    ci.total_sales,
    ci.order_count,
    ci.avg_net_profit,
    di.ca_state
FROM 
    customer_sales ci
JOIN 
    demographic_info di ON ci.c_customer_sk = di.cd_demo_sk
WHERE 
    ci.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
ORDER BY 
    ci.total_sales DESC
LIMIT 10;
