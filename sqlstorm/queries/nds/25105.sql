
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        ROW_NUMBER() OVER(PARTITION BY ca_city ORDER BY ca_address_sk) AS address_rank
    FROM 
        customer_address
),
FilteredDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        CASE 
            WHEN cd_purchase_estimate > 1000 THEN 'High Potential' 
            ELSE 'Low Potential' 
        END AS purchase_potential
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F' AND 
        cd_marital_status = 'M'
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER(ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    a.full_address,
    d.cd_gender,
    d.purchase_potential,
    s.total_quantity,
    s.total_sales,
    s.order_count,
    a.address_rank,
    s.sales_rank
FROM 
    AddressData a
JOIN 
    FilteredDemographics d ON a.ca_address_sk = d.cd_demo_sk
JOIN 
    SalesSummary s ON a.ca_address_sk = s.ws_item_sk
WHERE 
    a.address_rank <= 10 AND 
    s.sales_rank <= 20
ORDER BY 
    total_sales DESC, 
    full_address;
