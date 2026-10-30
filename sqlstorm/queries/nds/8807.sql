
WITH sales_data AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_order_number,
        w.w_warehouse_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
),
aggregated_sales AS (
    SELECT 
        w_warehouse_name,
        d_year,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ca_city) AS unique_cities,
        COUNT(DISTINCT cd_credit_rating) AS unique_credit_ratings
    FROM 
        sales_data
    GROUP BY 
        w_warehouse_name, d_year
)
SELECT 
    d_year,
    w_warehouse_name,
    total_sales,
    total_orders,
    unique_cities,
    unique_credit_ratings,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM 
    aggregated_sales
ORDER BY 
    d_year, sales_rank;
