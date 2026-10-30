
SELECT 
    CA.ca_address_id AS address_id,
    CA.ca_street_number || ' ' || CA.ca_street_name || ' ' || CA.ca_street_type AS full_address,
    C.c_first_name || ' ' || C.c_last_name AS customer_name,
    CD.cd_gender AS gender,
    CD.cd_marital_status AS marital_status,
    D.d_date AS purchase_date,
    I.i_item_desc AS item_description,
    WS.ws_sales_price AS sales_price,
    WS.ws_quantity AS quantity_sold,
    WS.ws_ext_sales_price AS total_sales_value,
    CASE
        WHEN C.c_birth_month = 12 THEN 'Holiday Season'
        WHEN C.c_birth_month IN (6, 7) THEN 'Summer Sales'
        ELSE 'Regular Season'
    END AS sales_season
FROM 
    customer C
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
JOIN 
    web_sales WS ON C.c_customer_sk = WS.ws_bill_customer_sk
JOIN 
    item I ON WS.ws_item_sk = I.i_item_sk
JOIN 
    date_dim D ON WS.ws_sold_date_sk = D.d_date_sk
WHERE 
    D.d_year = 2023
AND 
    (CD.cd_gender = 'F' OR CD.cd_marital_status = 'M')
AND 
    I.i_category LIKE '%Electronics%'
ORDER BY 
    total_sales_value DESC;
