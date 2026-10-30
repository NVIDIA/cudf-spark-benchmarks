
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
DateSummary AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
CustomerStatistics AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.full_name, 
        ci.ca_city, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.cd_education_status, 
        ci.cd_purchase_estimate, 
        ci.cd_credit_rating
)
SELECT 
    cs.full_name,
    cs.ca_city,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.cd_purchase_estimate,
    cs.cd_credit_rating,
    cs.num_orders,
    cs.total_spent,
    ds.total_orders AS overall_total_orders,
    ds.total_sales AS overall_total_sales,
    ds.avg_order_value AS average_order_value_per_order
FROM 
    CustomerStatistics cs
JOIN 
    DateSummary ds ON ds.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStatistics)
ORDER BY 
    cs.total_spent DESC;
