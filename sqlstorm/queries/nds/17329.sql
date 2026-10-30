
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    sa.ca_city, 
    sa.ca_state, 
    CASE 
        WHEN d.d_year < 2020 THEN 'Before 2020' 
        ELSE '2020 and After' 
    END AS period
FROM 
    customer c
JOIN 
    customer_address sa ON c.c_current_addr_sk = sa.ca_address_sk
JOIN 
    date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
WHERE 
    sa.ca_state = 'CA'
ORDER BY 
    c.c_last_name, c.c_first_name;
