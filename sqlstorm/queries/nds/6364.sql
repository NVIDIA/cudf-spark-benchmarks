
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_net_paid) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    CASE 
        WHEN cd_gender = 'F' THEN 'Female'
        WHEN cd_gender = 'M' THEN 'Male'
        ELSE 'Unknown' 
    END AS gender,
    d.d_year,
    ca.ca_city
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    d.d_year >= 2020 
    AND d.d_year <= 2023
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    cd_gender, 
    d.d_year, 
    ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 100;
