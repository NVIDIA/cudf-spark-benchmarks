WITH sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales,
        AVG(cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
customer_summary AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk
),
product_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= cast('2002-10-01' as date))
)
SELECT 
    pd.i_item_id,
    pd.i_product_name,
    pd.i_brand,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_sales_price,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.highest_credit_rating
FROM 
    product_details pd
LEFT JOIN 
    sales_summary ss ON pd.i_item_sk = ss.cs_item_sk
LEFT JOIN 
    customer_summary cs ON pd.i_item_sk = cs.cd_demo_sk
ORDER BY 
    ss.total_sales DESC
LIMIT 100;