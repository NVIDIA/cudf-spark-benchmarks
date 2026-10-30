
WITH CustomerData AS (
    SELECT 
        c.c_customer_id, 
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip,
        concat_ws(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
        d.d_date AS sales_date,
        w.w_warehouse_name,
        ws.ws_sales_price,
        ws.ws_quantity
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'S'
),
SalesSummary AS (
    SELECT 
        full_name, 
        count(*) AS total_orders, 
        sum(ws_sales_price) AS total_spent
    FROM 
        CustomerData
    GROUP BY 
        full_name
)
SELECT 
    full_name, 
    total_orders, 
    total_spent, 
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    SalesSummary
ORDER BY 
    total_spent DESC, 
    total_orders DESC;
