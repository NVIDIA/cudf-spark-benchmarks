WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
monthly_purchase AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS purchase_year,
        EXTRACT(MONTH FROM d.d_date) AS purchase_month,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        EXTRACT(YEAR FROM d.d_date), EXTRACT(MONTH FROM d.d_date)
),
income_distribution AS (
    SELECT 
        CASE 
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS income_band,
        COUNT(*) AS customer_count
    FROM 
        customer_demographics cd
    GROUP BY 
        CASE 
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    mp.purchase_year,
    mp.purchase_month,
    mp.total_sales,
    id.income_band,
    id.customer_count
FROM 
    customer_info ci
JOIN 
    monthly_purchase mp ON EXTRACT(YEAR FROM cast('2002-10-01' as date)) = mp.purchase_year AND EXTRACT(MONTH FROM cast('2002-10-01' as date)) = mp.purchase_month
JOIN 
    income_distribution id ON (
        (ci.cd_purchase_estimate < 10000 AND id.income_band = 'Low') OR
        (ci.cd_purchase_estimate BETWEEN 10000 AND 50000 AND id.income_band = 'Medium') OR
        (ci.cd_purchase_estimate > 50000 AND id.income_band = 'High')
    )
ORDER BY 
    mp.total_sales DESC, ci.full_name ASC;