
WITH  sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_item_sk) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        (SELECT COUNT(hd.hd_dep_count) 
         FROM household_demographics hd 
         WHERE hd.hd_demo_sk = c.c_current_hdemo_sk AND hd.hd_income_band_sk IS NOT NULL) AS household_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_current_hdemo_sk IS NOT NULL
),
sales_summary AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_quantity) AS total_quantity,
        AVG(sd.ws_ext_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ci.c_customer_id) AS customer_count
    FROM 
        sales_data sd
    JOIN 
        customer_info ci ON ci.c_customer_id IN (
            SELECT DISTINCT c.c_customer_id 
            FROM customer c 
            WHERE c.c_customer_sk IN (
                SELECT sr_customer_sk 
                FROM store_returns 
                WHERE sr_return_quantity > 0
            )
        )
    GROUP BY 
        sd.ws_order_number
)
SELECT 
    s.ws_order_number,
    s.total_quantity,
    s.avg_sales_price,
    s.customer_count,
    COALESCE(s.total_quantity * s.avg_sales_price, 0) AS total_revenue,
    CASE 
        WHEN s.total_quantity > 100 THEN 'High Volume'
        WHEN s.total_quantity IS NULL THEN 'No Sales'
        ELSE 'Normal Volume'
    END AS sales_category
FROM 
    sales_summary s
LEFT JOIN 
    (SELECT DISTINCT sm.sm_ship_mode_id FROM ship_mode sm) AS shipping_modes 
ON 
    shipping_modes.sm_ship_mode_id IS NOT NULL
ORDER BY 
    total_revenue DESC
LIMIT 100;
