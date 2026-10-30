
WITH AddressData AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE 
                   WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) 
                   ELSE '' 
               END) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
), 
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        ca_state
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
), 
SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
PromoData AS (
    SELECT 
        p_promo_sk,
        p_promo_name,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        promotion 
    JOIN 
        web_sales ON p_promo_sk = ws_promo_sk
    GROUP BY 
        p_promo_sk, p_promo_name
)
SELECT 
    a.full_address,
    c.full_name,
    c.cd_gender,
    s.total_quantity_sold,
    p.p_promo_name AS promo_name,
    p.order_count
FROM 
    AddressData a
JOIN 
    CustomerData c ON a.ca_state = c.ca_state
JOIN 
    SalesData s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN 
    PromoData p ON s.ws_item_sk = p.p_promo_sk
WHERE 
    a.ca_city LIKE 'New%'
ORDER BY 
    s.total_quantity_sold DESC, 
    c.full_name ASC
LIMIT 50;
