
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS customer_rank
    FROM 
        sales_summary cs
    JOIN 
        customer c ON cs.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
),
inventory_analysis AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS unique_warehouses
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    ia.inv_item_sk,
    sa.total_sales_quantity,
    sa.total_sales_amount,
    COALESCE(CASE WHEN tc.customer_rank <= 10 THEN 'Top Customer' ELSE 'Regular Customer' END, 'Unknown') AS customer_status,
    COALESCE(ia.total_quantity, 0) AS available_inventory,
    ia.unique_warehouses
FROM 
    top_customers tc
LEFT JOIN 
    sales_data sa ON tc.total_sales = sa.total_sales_amount
LEFT JOIN 
    inventory_analysis ia ON sa.ws_item_sk = ia.inv_item_sk
WHERE 
    tc.total_sales > (SELECT AVG(total_sales) FROM sales_summary) 
AND 
    (tc.cd_marital_status = 'M' OR tc.cd_marital_status = 'S')
ORDER BY 
    tc.total_sales DESC;

