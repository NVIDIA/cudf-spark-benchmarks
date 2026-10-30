
WITH sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                              (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_discount, 0) AS total_discount,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.cs_item_sk
),
demographics_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        SUM(ss.total_sales) AS demographic_total_sales
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        sales_summary ss ON ws.ws_item_sk = ss.cs_item_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, 
        cd.cd_credit_rating, cd.cd_dep_count, cd.cd_dep_college_count
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    i.i_current_price,
    di.cd_gender,
    di.cd_marital_status,
    di.demographic_total_sales,
    i.total_quantity_sold,
    i.total_sales,
    i.total_discount,
    i.total_orders
FROM 
    item_info i
JOIN 
    demographics_info di ON i.total_sales > 1000 AND di.demographic_total_sales > 50000
ORDER BY 
    i.total_sales DESC
LIMIT 100;
