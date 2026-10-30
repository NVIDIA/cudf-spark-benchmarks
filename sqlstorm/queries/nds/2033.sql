
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000 AND cd.cd_gender IS NOT NULL
),
item_info AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        COUNT(dw.ws_sold_date_sk) AS total_sales,
        SUM(dw.ws_sales_price) AS total_revenue
    FROM 
        item i
    LEFT JOIN 
        web_sales dw ON i.i_item_sk = dw.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        i.i_item_id, i.i_product_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(cs.cs_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        cs.cs_sold_date_sk = (SELECT MAX(cs_inner.cs_sold_date_sk) FROM catalog_sales cs_inner)
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(cs.cs_ext_sales_price) > 5000
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ii.i_product_name,
    ii.total_sales,
    ii.total_revenue,
    hvc.total_spent
FROM 
    customer_info ci
JOIN 
    item_info ii ON ii.total_sales > 0
JOIN 
    high_value_customers hvc ON ci.c_customer_id = hvc.c_customer_id
WHERE 
    ci.rn <= 5
ORDER BY 
    ii.total_revenue DESC, ci.c_last_name ASC
LIMIT 10;
