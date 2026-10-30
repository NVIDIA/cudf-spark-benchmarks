
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_promotions AS (
    SELECT 
        i.i_item_sk,
        p.p_promo_id,
        p.p_discount_active,
        p.p_promo_name,
        COUNT(*) AS promo_count
    FROM 
        item i
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk
    GROUP BY 
        i.i_item_sk, p.p_promo_id, p.p_discount_active, p.p_promo_name
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        ip.promo_count,
        ROW_NUMBER() OVER (PARTITION BY ci.c_customer_sk ORDER BY SUM(sd.total_sales) DESC) AS sales_rank
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
    LEFT JOIN 
        item_promotions ip ON sd.ws_item_sk = ip.i_item_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ip.promo_count
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS customer_rank
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_quantity,
    tc.total_sales,
    COALESCE(tc.promo_count, 0) AS promo_count,
    CASE 
        WHEN tc.sales_rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    top_customers tc
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    tc.total_sales DESC;
