WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20000101 AND 20001231
), CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 1000
), AddressDetails AS (
    SELECT 
        c_customer_sk,
        ca_state,
        ca_city,
        CASE 
            WHEN ca_zip LIKE '94%' THEN 'California'
            ELSE 'Other'
        END AS region
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ad.ca_city,
    COUNT(DISTINCT rs.ws_item_sk) AS total_distinct_items,
    AVG(rs.ws_sales_price) AS avg_sales_price,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    RankedSales rs
JOIN 
    AddressDetails ad ON rs.ws_bill_customer_sk = ad.c_customer_sk
JOIN 
    CustomerDemographics cd ON rs.ws_bill_customer_sk = cd.cd_demo_sk
WHERE 
    rank_sales <= 5
GROUP BY 
    ad.ca_city, cd.cd_gender, cd.cd_marital_status
HAVING 
    COUNT(DISTINCT rs.ws_item_sk) > 10
ORDER BY 
    avg_sales_price DESC
LIMIT 10;