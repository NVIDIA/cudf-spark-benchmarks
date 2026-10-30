
WITH Combined_Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ad.ca_city,
        ad.ca_state,
        d.d_date AS last_purchase_date,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ad.ca_state IN ('CA', 'TX', 'NY') AND
        cd.cd_purchase_estimate > 1000
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    c.ca_city,
    c.ca_state,
    c.last_purchase_date,
    c.d_month_seq,
    COUNT(*) AS purchase_count,
    SUM(ws.ws_sales_price) AS total_spent
FROM 
    Combined_Customer_Info c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    c.rn = 1
GROUP BY 
    full_name, c.c_email_address, c.ca_city, c.ca_state, c.last_purchase_date, c.d_month_seq
ORDER BY 
    total_spent DESC
LIMIT 10;
