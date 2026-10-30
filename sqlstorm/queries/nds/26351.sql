
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        (SELECT COUNT(*) FROM store s WHERE s.s_city = ca.ca_city AND s.s_state = ca.ca_state) AS store_count,
        (SELECT COUNT(*) FROM web_site ws WHERE ws.web_city = ca.ca_city AND ws.web_state = ca.ca_state) AS web_site_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_web_sales_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.store_count,
    ci.web_site_count,
    COALESCE(sd.total_web_sales_profit, 0) AS total_web_sales_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    (ci.cd_marital_status = 'M' AND ci.cd_purchase_estimate > 1000) OR 
    (ci.cd_marital_status = 'S' AND ci.cd_purchase_estimate > 500)
ORDER BY 
    total_web_sales_profit DESC;
