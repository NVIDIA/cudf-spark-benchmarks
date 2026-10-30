
SELECT 
    C.c_customer_id,
    CONCAT(C.c_first_name, ' ', C.c_last_name) AS full_name,
    A.ca_city,
    A.ca_state,
    A.ca_zip,
    D.d_year,
    SUM(CASE 
        WHEN S.ss_sales_price IS NOT NULL THEN S.ss_sales_price * S.ss_quantity 
        ELSE W.ws_sales_price * W.ws_quantity 
    END) AS total_sales,
    COUNT(DISTINCT CASE 
        WHEN S.ss_sales_price IS NOT NULL THEN S.ss_ticket_number 
        ELSE W.ws_order_number 
    END) AS total_transactions
FROM 
    customer C
JOIN 
    customer_address A ON C.c_current_addr_sk = A.ca_address_sk
LEFT JOIN 
    store_sales S ON C.c_customer_sk = S.ss_customer_sk
LEFT JOIN 
    web_sales W ON C.c_customer_sk = W.ws_bill_customer_sk
JOIN 
    date_dim D ON D.d_date_sk IN (S.ss_sold_date_sk, W.ws_sold_date_sk)
WHERE 
    A.ca_state = 'CA' 
    AND D.d_year = 2023
GROUP BY 
    C.c_customer_id, C.c_first_name, C.c_last_name, A.ca_city, A.ca_state, A.ca_zip, D.d_year
ORDER BY 
    total_sales DESC 
LIMIT 10;
