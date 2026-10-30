
WITH  sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND ws.ws_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        w.w_warehouse_id
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ca.ca_city, 
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS order_count, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        (cd.cd_gender = 'M' OR (cd.cd_gender IS NULL AND ca.ca_state = 'CA'))
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state
),
final_summary AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender AS gender,
        ci.cd_marital_status AS marital_status,
        AVG(ci.total_spent) AS avg_spent,
        SUM(ss.total_sales) AS warehouse_sales
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_id = ss.w_warehouse_id
    GROUP BY 
        ci.c_customer_id, ci.cd_gender, ci.cd_marital_status
)
SELECT 
    * 
FROM 
    final_summary 
WHERE 
    (avg_spent > (SELECT AVG(total_spent) FROM customer_info) OR warehouse_sales IS NOT NULL)
    AND (avg_spent IS NOT NULL OR warehouse_sales > 10000);
