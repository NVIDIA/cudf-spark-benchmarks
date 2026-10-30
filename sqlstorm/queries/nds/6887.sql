
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
most_valuable_customers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name, 
        rc.cd_gender, 
        rc.cd_marital_status, 
        rc.cd_purchase_estimate
    FROM 
        ranked_customers rc
    WHERE 
        rc.rn <= 5
)
SELECT 
    w.w_warehouse_name, 
    SUM(ws.ws_quantity) AS total_quantity_sold, 
    SUM(ws.ws_sales_price) AS total_sales_value
FROM 
    web_sales ws
JOIN 
    most_valuable_customers mvc ON ws.ws_bill_customer_sk = mvc.c_customer_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    w.w_warehouse_name
ORDER BY 
    total_quantity_sold DESC, total_sales_value DESC;
