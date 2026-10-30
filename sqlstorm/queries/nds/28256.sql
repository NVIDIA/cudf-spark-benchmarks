
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        customer_sk,
        COUNT(*) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent,
        AVG(ws_ext_sales_price) AS avg_order_value,
        STRING_AGG(DISTINCT COALESCE(start_item, 'No Items'), ', ') AS distinct_items_purchased
    FROM (
        SELECT 
            ws_bill_customer_sk AS customer_sk, 
            ws_ext_sales_price,
            i.i_item_id AS start_item
        FROM 
            web_sales 
        LEFT JOIN 
            item i ON web_sales.ws_item_sk = i.i_item_sk
        UNION ALL 
        SELECT 
            ss_customer_sk AS customer_sk, 
            ss_ext_sales_price,
            i.i_item_id AS start_item
        FROM 
            store_sales 
        LEFT JOIN 
            item i ON store_sales.ss_item_sk = i.i_item_sk
    ) orders
    GROUP BY 
        customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    cd.cd_dep_count,
    cd.cd_dep_employed_count,
    cd.cd_dep_college_count,
    cd.ca_city,
    cd.ca_state,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_spent, 0) AS total_spent,
    COALESCE(ss.avg_order_value, 0.00) AS avg_order_value,
    COALESCE(ss.distinct_items_purchased, 'No Items') AS distinct_items_purchased
FROM 
    customer_data cd
LEFT JOIN 
    sales_summary ss ON cd.c_customer_sk = ss.customer_sk
ORDER BY 
    cd.cd_purchase_estimate DESC, cd.full_name ASC
LIMIT 100;
