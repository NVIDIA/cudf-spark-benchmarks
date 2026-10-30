
WITH  sales_totals AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT 
        si.i_item_id,
        si.i_product_name,
        st.total_sales,
        st.total_orders
    FROM sales_totals st
    JOIN item si ON st.ws_item_sk = si.i_item_sk
    WHERE st.rank <= 10
),
customer_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ca.cd_gender,
    ca.cd_marital_status,
    ca.total_spent,
    ca.unique_customers,
    ca.avg_order_value,
    CASE 
        WHEN ca.total_spent IS NULL THEN 'No Sales' 
        ELSE 'Sales Present' 
    END AS sales_status
FROM top_items ti
FULL OUTER JOIN customer_analysis ca ON ti.total_orders = ca.unique_customers
ORDER BY ti.total_sales DESC, ca.total_spent DESC
LIMIT 20;
