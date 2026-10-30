
WITH CustomerPurchaseData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        cp.c_customer_id,
        cp.total_quantity,
        cp.total_net_paid,
        CASE 
            WHEN cp.total_net_paid > 1000 THEN 'High'
            WHEN cp.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS value_segment
    FROM 
        CustomerPurchaseData cp
    WHERE 
        cp.total_orders > 5
),
CustomerAddressInfo AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.total_quantity,
    hvc.total_net_paid,
    hvc.value_segment,
    cai.ca_city,
    cai.ca_state,
    sd.total_sales AS item_total_sales,
    CASE 
        WHEN sd.rank = 1 THEN 'Top Seller'
        ELSE 'Regular Item'
    END AS item_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerAddressInfo cai ON hvc.c_customer_id = cai.c_customer_id
FULL OUTER JOIN 
    SalesData sd ON sd.quantity_sold IS NOT NULL
WHERE 
    hvc.total_net_paid IS NOT NULL
AND 
    (cai.ca_city IS NULL OR cai.ca_state IS NOT NULL OR hvc.total_quantity < 100)
ORDER BY 
    hvc.value_segment DESC, 
    sd.total_sales DESC
LIMIT 50;
