
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales
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
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
popular_items AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.total_quantity) AS gross_sold
    FROM 
        sales_summary s
    GROUP BY 
        s.ws_item_sk
    HAVING 
        SUM(s.total_quantity) > (
            SELECT 
                AVG(total_quantity) 
            FROM 
                sales_summary
        )
),
sales_dates AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS rn
    FROM 
        date_dim d
    WHERE 
        d.d_date >= '2023-01-01' AND d.d_date <= '2023-12-31'
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.hd_income_band_sk,
    ci.hd_buy_potential,
    SUM(ss.total_quantity) AS total_quantity_sold,
    SUM(ss.total_net_paid) AS total_sales_value,
    MAX(sd.d_date) AS last_sale_date
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
JOIN 
    popular_items pi ON ss.ws_item_sk = pi.ws_item_sk
JOIN 
    sales_dates sd ON ss.ws_sold_date_sk = sd.d_date_sk
WHERE 
    ci.cd_purchase_estimate IS NOT NULL
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_purchase_estimate, 
    ci.hd_income_band_sk, 
    ci.hd_buy_potential
ORDER BY 
    total_sales_value DESC
LIMIT 10;
