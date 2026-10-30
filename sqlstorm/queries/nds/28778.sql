
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY c.c_customer_sk) AS state_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND ca.ca_country = 'USA'
),
Sales_Info AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
Benchmark AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        si.total_quantity,
        si.total_sales,
        ROUND(AVG(si.total_sales) OVER (PARTITION BY ci.ca_state), 2) AS avg_sales_per_state
    FROM 
        Customer_Info ci
    LEFT JOIN 
        Sales_Info si ON ci.c_customer_sk = si.ws_item_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_quantity,
    total_sales,
    avg_sales_per_state,
    CASE 
        WHEN total_sales > avg_sales_per_state THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    Benchmark
ORDER BY 
    ca_state, total_sales DESC;
