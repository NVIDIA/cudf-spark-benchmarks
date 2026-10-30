
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_summary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        COUNT(DISTINCT ca.ca_address_id) AS unique_addresses
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
),
yearly_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    asu.num_customers,
    asu.unique_addresses,
    ys.total_sales
FROM 
    ranked_customers rc
JOIN 
    address_summary asu ON rc.c_customer_sk IN (
        SELECT c.c_customer_sk
        FROM customer_address ca
        JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE ca.ca_state IN ('CA', 'NY')
    )
JOIN 
    yearly_sales ys ON ys.d_year = 2023
WHERE 
    rc.rank_by_purchase <= 10;
