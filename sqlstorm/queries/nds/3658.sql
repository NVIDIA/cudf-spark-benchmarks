WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2459109 AND 2459119 
    GROUP BY 
        ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'N/A' 
            ELSE cd.cd_credit_rating 
        END AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
top_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        ranked_sales rs 
    WHERE 
        rs.sales_rank <= 10
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.credit_rating,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(ts.total_sales / NULLIF(ts.total_quantity, 0), 0) AS avg_sale_per_item,
    (SELECT COUNT(*) FROM store s WHERE s.s_number_employees IS NOT NULL) AS active_stores
FROM 
    customer_info ci
JOIN 
    top_sales ts ON ci.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ts.ws_item_sk)
ORDER BY 
    ts.total_sales DESC;