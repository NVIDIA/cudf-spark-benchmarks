
WITH CustomerAddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
            CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        LOWER(cd_education_status) AS education_status,
        CASE 
            WHEN cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_capacity,
        cd_credit_rating
    FROM 
        customer_demographics
),
RecentPurchases AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = DATE '2002-10-01' - INTERVAL '30 day')
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_id,
        d.education_status,
        d.purchase_capacity,
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        rp.total_spent,
        rp.total_orders
    FROM 
        customer c
    LEFT JOIN 
        CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        CustomerAddressDetails ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        RecentPurchases rp ON c.c_customer_sk = rp.customer_id
)
SELECT 
    c.c_customer_id AS customer_id,
    c.education_status,
    c.purchase_capacity,
    c.full_address,
    c.ca_city,
    c.ca_state,
    c.ca_country,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(c.total_orders, 0) AS total_orders,
    CASE 
        WHEN COALESCE(c.total_spent, 0) > 5000 THEN 'VIP'
        WHEN COALESCE(c.total_orders, 0) >= 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Shopper'
    END AS customer_status
FROM 
    CombinedData c
WHERE 
    c.education_status LIKE '%university%'
ORDER BY 
    total_spent DESC;
