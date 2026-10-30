
SELECT 
    CA.ca_city,
    CA.ca_state,
    CONCAT(CA.ca_street_number, ' ', CA.ca_street_name, ' ', CA.ca_street_type) AS full_address,
    C.c_first_name,
    C.c_last_name,
    CD.cd_gender,
    CASE 
        WHEN CD.cd_marital_status = 'M' THEN 'Married'
        WHEN CD.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Unknown'
    END AS marital_status,
    SUM(COALESCE(SS.ss_sales_price, 0)) AS total_spent,
    COUNT(DISTINCT SS.ss_ticket_number) AS purchase_count
FROM 
    customer C
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
LEFT JOIN 
    store_sales SS ON C.c_customer_sk = SS.ss_customer_sk 
WHERE 
    CA.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    CA.ca_city, CA.ca_state, full_address, C.c_first_name, C.c_last_name, CD.cd_gender, CD.cd_marital_status
ORDER BY 
    total_spent DESC
LIMIT 100;
