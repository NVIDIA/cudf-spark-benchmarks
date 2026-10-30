
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_birth_year DESC) AS city_rank
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        ca.ca_country = 'USA'
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(cs.cs_order_number) AS promotion_usage
    FROM 
        promotion p
    LEFT JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ad.full_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    p.p_promo_name,
    cs.total_orders,
    cs.total_spent
FROM 
    AddressDetails ad
LEFT JOIN 
    Promotions p ON p.p_promo_name LIKE '%' || 'Discount' || '%'
LEFT JOIN 
    CustomerSummary cs ON ad.full_name = cs.c_customer_id
WHERE 
    ad.city_rank <= 5
ORDER BY 
    ad.ca_city ASC, cs.total_spent DESC
LIMIT 100;
