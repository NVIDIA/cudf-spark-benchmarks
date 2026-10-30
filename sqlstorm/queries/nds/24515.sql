
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 30
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        CASE 
            WHEN inv.inv_quantity_on_hand IS NULL THEN 'Stock Unavailable'
            WHEN inv.inv_quantity_on_hand < 5 THEN 'Low Stock'
            ELSE 'Sufficient Stock' 
        END AS stock_status
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = 1
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
sales_with_stock AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        COALESCE(ic.inv_quantity_on_hand, 0) AS available_quantity,
        CASE 
            WHEN ic.inv_quantity_on_hand < cs.cs_quantity THEN 'Insufficient Stock'
            ELSE 'Available' 
        END AS order_status
    FROM 
        catalog_sales cs
    LEFT JOIN 
        inventory_check ic ON cs.cs_item_sk = ic.inv_item_sk
)
SELECT 
    cstm.c_first_name || ' ' || cstm.c_last_name AS customer_name,
    sss.cs_order_number,
    sss.cs_item_sk,
    sss.available_quantity,
    CASE 
        WHEN sss.order_status = 'Available' AND rs.rank_sales <= 5 THEN 'Top Sale'
        ELSE 'Regular Sale'
    END AS sale_type,
    RANK() OVER (PARTITION BY sss.cs_item_sk ORDER BY sss.cs_net_paid DESC) AS rank_net_paid,
    SUM(sss.cs_net_paid) OVER (PARTITION BY sss.cs_item_sk) AS total_paid_item
FROM 
    sales_with_stock sss
JOIN 
    customer_summary cstm ON sss.cs_order_number = cstm.total_orders
LEFT JOIN 
    ranked_sales rs ON sss.cs_item_sk = rs.ws_item_sk
WHERE 
    sss.available_quantity > 0
    AND (rs.rank_sales IS NULL OR rs.rank_sales <= 10)
ORDER BY 
    customer_name, sale_type;
