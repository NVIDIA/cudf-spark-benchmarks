
WITH  Sales_History AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), Item_Stats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(sh.total_sales, 0) AS total_sales,
        COALESCE(sh.order_count, 0) AS order_count,
        CASE 
            WHEN sh.sales_rank IS NULL THEN 'Not Sold'
            ELSE 'Sold'
        END AS sold_status
    FROM 
        item i
    LEFT JOIN 
        Sales_History sh ON i.i_item_sk = sh.ws_item_sk
), Customer_Agg AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        MIN(cd.cd_purchase_estimate) AS min_purchase_estimate,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    i.i_item_id,
    i.total_sales,
    i.order_count,
    ca.total_orders,
    ca.total_spent,
    CASE 
        WHEN i.order_count = 0 THEN 'No Orders'
        WHEN i.total_sales > 1000 THEN 'High Seller'
        ELSE 'Low Seller'
    END AS sales_category,
    d.cd_gender,
    d.min_purchase_estimate,
    d.max_purchase_estimate,
    d.customer_count
FROM 
    Item_Stats i
JOIN 
    Customer_Agg ca ON i.i_item_sk = ca.c_customer_sk
LEFT JOIN 
    Demographics d ON d.customer_count > 100
WHERE 
    (i.total_sales IS NOT NULL OR i.order_count IS NOT NULL)
    AND (d.min_purchase_estimate < 500 OR d.max_purchase_estimate IS NULL)
ORDER BY 
    i.total_sales DESC, ca.total_spent DESC;

