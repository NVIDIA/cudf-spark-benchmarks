
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
HighValueSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        RankedSales rs
    JOIN 
        web_sales ws ON rs.ws_item_sk = ws.ws_item_sk AND rs.ws_order_number = ws.ws_order_number
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    WHERE 
        rs.sales_rank = 1
    GROUP BY 
        item.i_item_id, item.i_product_name
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesByState AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_sales_price) AS sales_total
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
    HAVING 
        SUM(ws.ws_sales_price) > (
            SELECT AVG(total_sales) 
            FROM (
                SELECT SUM(ws_sales_price) AS total_sales 
                FROM web_sales 
                GROUP BY ws_bill_customer_sk
            ) AS avg_sales
        )
)
SELECT 
    cs.c_customer_id,
    cs.max_purchase_estimate,
    COALESCE(hv.total_sales, 0) AS total_sales,
    COALESCE(sbs.sales_total, 0) AS total_sales_by_state,
    CASE 
        WHEN cs.total_orders IS NULL THEN 'No orders'
        ELSE 'Orders exist'
    END AS order_status,
    CASE 
        WHEN cs.max_purchase_estimate IS NOT NULL AND cs.max_purchase_estimate > 1000 THEN 'High Potential'
        ELSE 'Standard Potential'
    END AS customer_potential
FROM 
    CustomerStats cs
LEFT JOIN 
    HighValueSales hv ON cs.c_customer_id = hv.i_item_id
LEFT JOIN 
    SalesByState sbs ON cs.c_customer_id = sbs.ca_state
WHERE 
    (cs.total_orders IS NULL OR cs.max_purchase_estimate >= 500)
ORDER BY 
    cs.max_purchase_estimate DESC, total_sales DESC
LIMIT 
    100;
