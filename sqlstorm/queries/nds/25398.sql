
SELECT 
    CONCAT(C.c_first_name, ' ', C.c_last_name) AS full_name,
    CA.ca_city AS city,
    COUNT(DISTINCT WS.ws_order_number) AS total_orders,
    SUM(WS.ws_net_paid) AS total_spent,
    AVG(CASE 
            WHEN CD.cd_gender = 'M' THEN WS.ws_net_paid 
            ELSE NULL 
        END) AS average_spent_men,
    AVG(CASE 
            WHEN CD.cd_gender = 'F' THEN WS.ws_net_paid 
            ELSE NULL 
        END) AS average_spent_women,
    DT.d_year AS year,
    EXTRACT(MONTH FROM DT.d_date) AS month,
    CASE 
        WHEN CD.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status
FROM 
    customer C
JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
JOIN 
    web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
JOIN 
    date_dim DT ON WS.ws_sold_date_sk = DT.d_date_sk
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
WHERE 
    DT.d_year BETWEEN 2020 AND 2023
GROUP BY 
    C.c_first_name, 
    C.c_last_name, 
    CA.ca_city, 
    DT.d_year, 
    CD.cd_marital_status,
    DT.d_date
ORDER BY 
    total_spent DESC, 
    full_name;
