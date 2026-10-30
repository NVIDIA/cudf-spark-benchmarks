
WITH enriched_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_date AS order_date,
        t.t_hour AS order_hour,
        ws.ws_sales_price,
        ws.ws_quantity
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE 
        ws.ws_sales_price > 100.00
        AND d.d_year = 2023
),
city_analysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales
    FROM 
        enriched_data
    GROUP BY 
        ca_city, ca_state
)
SELECT 
    ca_city,
    ca_state,
    customer_count,
    total_sales,
    avg_sales,
    CASE 
        WHEN total_sales >= 10000 THEN 'High Revenue'
        WHEN total_sales BETWEEN 5000 AND 9999 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    city_analysis
ORDER BY 
    total_sales DESC
LIMIT 10;
