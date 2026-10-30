
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS registration_date,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_summary AS (
    SELECT 
        ci.full_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        d.d_year AS sales_year
    FROM 
        web_sales ws
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ci.full_name, d.d_year
),
ranked_sales AS (
    SELECT 
        full_name,
        total_quantity,
        total_sales_amount,
        sales_year,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    full_name, 
    total_quantity, 
    total_sales_amount, 
    sales_year, 
    sales_rank
FROM 
    ranked_sales 
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_year, sales_rank;
