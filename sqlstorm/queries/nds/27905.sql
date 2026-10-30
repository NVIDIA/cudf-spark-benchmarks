WITH AddressAggregation AS (
    SELECT 
        ca_state,
        CONCAT(ca_city, ', ', ca_street_name, ' ', ca_street_number) AS full_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city, ca_street_name, ca_street_number
),
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies
    FROM 
        customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
WebSalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    a.ca_state,
    a.full_address,
    c.cd_gender,
    c.cd_marital_status,
    c.total_customers,
    c.avg_purchase_estimate,
    c.total_dependencies,
    w.total_quantity_sold,
    w.total_net_profit
FROM 
    AddressAggregation a
JOIN 
    CustomerStats c ON a.ca_state = CASE 
                                         WHEN c.cd_gender = 'F' THEN 'CA' 
                                         ELSE 'NY' 
                                     END
JOIN 
    WebSalesSummary w ON w.ws_item_sk IN (
        SELECT i_item_sk FROM item WHERE i_brand = 'Nike'
    )
ORDER BY 
    a.ca_state, c.total_customers DESC;