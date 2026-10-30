
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(sr.sr_item_sk) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male' 
        ELSE 'Female' 
    END AS customer_gender,
    EXTRACT(YEAR FROM d.d_date) AS return_year,
    SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_quantity ELSE 0 END) AS total_returned_quantity,
    STRING_AGG(DISTINCT r.r_reason_desc, ', ') AS return_reasons
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, return_year
ORDER BY 
    total_returns DESC, total_return_amount DESC
LIMIT 100;
