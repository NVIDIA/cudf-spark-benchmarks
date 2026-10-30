
WITH sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit / NULLIF(ws_ext_sales_price, 0)) * 100 AS profit_margin_percentage
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        h.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk, 
        ss.total_sales,
        cs.cs_sales_price,
        cs.cs_list_price
    FROM 
        sales_summary ss
    INNER JOIN 
        catalog_sales cs ON ss.ws_item_sk = cs.cs_item_sk
    ORDER BY 
        ss.total_sales DESC
    LIMIT 10
)
SELECT 
    td.c_last_name,
    td.c_first_name,
    td.cd_gender,
    td.cd_marital_status,
    ti.total_sales,
    ti.cs_sales_price,
    ti.cs_list_price,
    ss.total_discount,
    ss.total_net_paid,
    ss.order_count,
    ss.profit_margin_percentage,
    h.ib_lower_bound,
    h.ib_upper_bound
FROM 
    top_items ti
JOIN 
    customer_details td ON ti.ws_item_sk = td.c_customer_sk
JOIN 
    income_band h ON td.hd_income_band_sk = h.ib_income_band_sk
JOIN 
    sales_summary ss ON ti.ws_item_sk = ss.ws_item_sk
WHERE 
    td.cd_purchase_estimate > 1000
ORDER BY 
    ti.total_sales DESC, td.c_last_name;
