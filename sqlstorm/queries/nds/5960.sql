WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458820 AND 2458880 
    GROUP BY 
        ws_item_sk
), 
customer_details AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        c.c_first_name,
        c.c_last_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales,
        ss.total_quantity,
        ss.total_orders,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS rank
    FROM 
        sales_summary ss
    WHERE 
        ss.total_orders > 5 
),
detailed_info AS (
    SELECT 
        ti.rank,
        ti.total_sales,
        ti.total_quantity,
        ti.total_orders,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        top_items ti
    JOIN 
        web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
    JOIN 
        customer_details cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        ti.rank <= 10  
)
SELECT 
    di.rank,
    di.total_sales,
    di.total_quantity,
    di.total_orders,
    di.c_first_name,
    di.c_last_name,
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status
FROM 
    detailed_info di
ORDER BY 
    di.rank;