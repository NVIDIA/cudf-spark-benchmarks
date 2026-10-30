
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        cs.cs_item_sk,
        cs.cs_order_number,
        COALESCE(ws.ws_net_profit, 0) - COALESCE(cs.cs_net_profit, 0) AS profit_diff
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
    WHERE 
        (ws.ws_ship_date_sk BETWEEN 1 AND 100) AND 
        (ws.ws_net_paid_inc_tax IS NOT NULL OR cs.cs_net_paid IS NOT NULL)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(cd.cd_purchase_estimate, 0) DESC) AS cust_rank
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        (cd.cd_purchase_estimate IS NOT NULL AND cd.cd_purchase_estimate > 500)
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(CASE WHEN ci.cust_rank = 1 THEN 1 ELSE 0 END) AS preferred_customers,
    AVG(sd.profit_diff) AS avg_profit_diff
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_info ci ON c.c_customer_sk = ci.c_customer_sk
LEFT JOIN 
    sales_data sd ON c.c_customer_sk IN (sd.ws_order_number, sd.cs_order_number)
WHERE 
    ca.ca_state IN ('NY', 'CA') AND 
    (ci.c_preferred_cust_flag = 'Y' OR ci.cust_rank <= 5)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_customers DESC, avg_profit_diff DESC;
