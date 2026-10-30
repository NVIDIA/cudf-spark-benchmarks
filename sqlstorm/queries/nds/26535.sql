
WITH Combined_Customer_Info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        (SELECT COUNT(*) FROM customer WHERE c_birth_year = c.c_birth_year) AS same_year_birth_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY')
),
Web_Sales_Growth AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        EXTRACT(YEAR FROM d.d_date)
),
Sales_Comparison AS (
    SELECT 
        sales_year,
        total_sales,
        LAG(total_sales) OVER (ORDER BY sales_year) AS previous_year_sales,
        (total_sales - LAG(total_sales) OVER (ORDER BY sales_year)) AS sales_growth
    FROM 
        Web_Sales_Growth
)
SELECT 
    c.c_customer_id,
    c.full_name,
    c.ca_city,
    c.ca_state,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    s.sales_year,
    s.total_sales,
    s.previous_year_sales,
    s.sales_growth
FROM 
    Combined_Customer_Info c
JOIN 
    Sales_Comparison s ON EXTRACT(YEAR FROM DATE '2002-10-01') - 1 = s.sales_year
WHERE 
    c.same_year_birth_count > 10 
ORDER BY 
    s.total_sales DESC;
