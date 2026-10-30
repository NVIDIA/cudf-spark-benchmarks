
WITH enriched_customer AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, ca.ca_city, ca.ca_state, ca.ca_country, 
        cd.cd_purchase_estimate, cd.cd_credit_rating
), 
city_ranked AS (
    SELECT 
        ca.ca_city,
        SUM(ec.total_sales) AS city_sales,
        RANK() OVER (ORDER BY SUM(ec.total_sales) DESC) AS city_rank
    FROM 
        enriched_customer ec
    JOIN 
        customer_address ca ON ec.ca_city = ca.ca_city
    GROUP BY 
        ca.ca_city
)

SELECT 
    ec.full_name,
    ec.gender,
    ec.ca_city,
    ec.ca_state,
    ec.ca_country,
    ec.order_count,
    ec.total_sales,
    cr.city_sales,
    cr.city_rank
FROM 
    enriched_customer ec
JOIN 
    city_ranked cr ON ec.ca_city = cr.ca_city
WHERE 
    ec.total_sales > 1000
ORDER BY 
    cr.city_rank, ec.total_sales DESC;
