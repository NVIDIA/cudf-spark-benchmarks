
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        TRIM(UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
SalesInfo AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_revenue
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
Combined AS (
    SELECT 
        a.full_address,
        a.ca_city,
        a.ca_state,
        s.total_quantity,
        s.total_revenue
    FROM 
        AddressInfo a
    LEFT JOIN 
        SalesInfo s ON a.ca_address_sk = s.ss_item_sk
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    COALESCE(total_quantity, 0) AS total_sales,
    COALESCE(total_revenue, 0.00) AS total_revenue,
    CONCAT('Sales in ', ca_city, ', ', ca_state, ': ', COALESCE(total_quantity, 0), ' units sold, $', COALESCE(total_revenue, 0.00)) AS sales_report
FROM 
    Combined
WHERE 
    ca_state IN ('CA', 'NY', 'TX')
ORDER BY 
    total_revenue DESC
LIMIT 100;
