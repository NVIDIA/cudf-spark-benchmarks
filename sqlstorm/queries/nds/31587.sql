
WITH  sales_cte AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_sales AS (
    SELECT 
        d.d_year,
        COALESCE(SUM(ws.ws_net_paid), 0) AS yearly_sales
    FROM 
        date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    sales_cte.total_sales,
    ds.yearly_sales,
    (SELECT COUNT(*) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = ci.c_customer_sk 
     AND ws.ws_sales_price > 100) AS high_value_purchases
FROM 
    customer_info ci
JOIN 
    sales_cte ON ci.c_customer_sk = sales_cte.ws_bill_customer_sk
JOIN 
    date_sales ds ON ds.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
WHERE 
    ci.cd_marital_status = 'S'
    AND ci.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
ORDER BY 
    sales_cte.total_sales DESC
LIMIT 50;
