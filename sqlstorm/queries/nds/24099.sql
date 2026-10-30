
WITH RecursiveCustomerAnalytics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_purchased,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_spent,
        COUNT(DISTINCT CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_order_number END) AS distinct_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_sales_price), 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
AddressWithSpecialCases AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN ca.ca_city IS NULL THEN 'No City'
            WHEN ca.ca_state IS NULL THEN 'No State'
            ELSE 'Complete Address'
        END AS address_status
    FROM 
        customer_address ca
    WHERE 
        NOT (ca.ca_city IS NULL AND ca.ca_state IS NULL)
),
RecentOrders AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        DENSE_RANK() OVER (ORDER BY ws.ws_ship_date_sk DESC) AS recent_rank
    FROM 
        web_sales ws
)
SELECT 
    rca.c_first_name,
    rca.c_last_name,
    rca.total_purchased,
    rca.total_spent,
    rca.distinct_orders,
    CASE 
        WHEN rca.rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    a.ca_city,
    a.ca_state,
    a.address_status,
    CASE 
        WHEN a.address_status = 'Complete Address' THEN 'Valid Address'
        ELSE 'Check Address'
    END AS address_validation,
    ro.ws_order_number
FROM 
    RecursiveCustomerAnalytics rca
JOIN 
    AddressWithSpecialCases a ON rca.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    RecentOrders ro ON rca.c_customer_sk = ro.ws_order_number
WHERE 
    rca.total_spent > (
        SELECT 
            AVG(total_spent)
        FROM 
            RecursiveCustomerAnalytics
    )
    AND (rca.total_purchased IS NOT NULL OR rca.total_spent IS NOT NULL)
ORDER BY 
    rca.total_spent DESC, rca.total_purchased DESC
LIMIT 100 OFFSET 10;
