
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_marital_status = 'M' 
      AND hd.hd_buy_potential IN ('Very Low', 'Low', 'Medium')
      AND cd.cd_purchase_estimate > 200
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        hd.hd_income_band_sk, 
        hd.hd_buy_potential
), average_spent AS (
    SELECT 
        hd_income_band_sk,
        AVG(total_spent) AS avg_spent
    FROM customer_data
    GROUP BY hd_income_band_sk
), order_count AS (
    SELECT 
        hd_income_band_sk,
        AVG(total_orders) AS avg_orders
    FROM customer_data
    GROUP BY hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    COALESCE(avg_spend.avg_spent, 0) AS average_spent,
    COALESCE(order_count.avg_orders, 0) AS average_orders
FROM income_band ib
LEFT JOIN average_spent avg_spend ON ib.ib_income_band_sk = avg_spend.hd_income_band_sk
LEFT JOIN order_count ON ib.ib_income_band_sk = order_count.hd_income_band_sk
ORDER BY ib.ib_income_band_sk;
