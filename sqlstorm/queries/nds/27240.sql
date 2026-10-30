
WITH AddressCity AS (
    SELECT DISTINCT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS city_address_cnt
    FROM 
        customer_address
    WHERE 
        LENGTH(ca_city) BETWEEN 5 AND 15
    GROUP BY 
        ca_city
), 
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_day IS NOT NULL
    GROUP BY 
        cd_gender, cd_marital_status
), 
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
)
SELECT 
    ac.ca_city,
    d.cd_gender,
    d.cd_marital_status,
    d.customer_count,
    d.total_dependents,
    d.avg_purchase_estimate,
    sd.total_sales,
    sd.order_count
FROM 
    AddressCity ac
JOIN 
    Demographics d ON d.customer_count > 10
LEFT JOIN 
    SalesData sd ON sd.ws_item_sk IN (SELECT i_item_sk FROM item WHERE LENGTH(i_product_name) > 10)
ORDER BY 
    ac.city_address_cnt DESC, d.customer_count DESC;
