
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        h.hd_income_band_sk,
        h.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'M' 
    AND h.hd_income_band_sk IS NOT NULL
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, h.hd_income_band_sk, h.hd_buy_potential
),
sales_data AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.hd_buy_potential,
    COALESCE(sd.monthly_sales, 0) AS average_monthly_sales,
    ci.total_orders
FROM customer_info ci
LEFT JOIN sales_data sd ON ci.total_sales > 0
ORDER BY ci.total_orders DESC, average_monthly_sales DESC
LIMIT 100;
