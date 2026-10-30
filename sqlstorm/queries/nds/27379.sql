
WITH Address_Analysis AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        ARRAY_AGG(DISTINCT ca_street_name) AS street_names,
        ARRAY_AGG(DISTINCT ca_street_type) AS street_types
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
    GROUP BY 
        ca_city, ca_state
),
Customer_Summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
Sales_Analysis AS (
    SELECT 
        i_item_id,
        SUM(ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        i_item_id
)
SELECT 
    aa.ca_city,
    aa.ca_state,
    aa.unique_addresses,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_dependents,
    sa.i_item_id,
    sa.total_quantity_sold,
    sa.total_orders,
    sa.avg_sales_price
FROM 
    Address_Analysis aa
JOIN 
    Customer_Summary cs ON aa.ca_state IN (SELECT DISTINCT ca_state FROM customer_address)
JOIN 
    Sales_Analysis sa ON sa.total_quantity_sold > 100
ORDER BY 
    aa.unique_addresses DESC, 
    cs.total_dependents DESC, 
    sa.total_quantity_sold DESC;
