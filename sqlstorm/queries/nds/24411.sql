
WITH  demo_incomes AS (
    SELECT hd_demo_sk, ib_income_band_sk
    FROM household_demographics h
    JOIN income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
    WHERE h.hd_buy_potential IS NOT NULL
    UNION ALL
    SELECT h.hd_demo_sk, i.ib_income_band_sk
    FROM household_demographics h
    JOIN income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
    WHERE h.hd_buy_potential IS NULL
    AND EXISTS (SELECT 1 FROM household_demographics h2 WHERE h2.hd_demo_sk = h.hd_demo_sk - 1)
),

sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_open_date_sk < 4000 AND (w.web_close_date_sk IS NULL OR w.web_close_date_sk > 4000)
    GROUP BY ws.ws_sold_date_sk
),

customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        SUM(CASE WHEN cd.cd_credit_rating = 'Good' THEN 1 ELSE 0 END) AS good_credit_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),

qualified_customers AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        ci.ib_income_band_sk,
        sd.total_sales,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY sd.total_sales DESC) AS sales_rank
    FROM customer_data cd
    JOIN demo_incomes ci ON ci.hd_demo_sk = CAST(cd.c_customer_id AS INT)
    LEFT JOIN sales_data sd ON sd.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    WHERE cd.max_purchase_estimate > 50000
)

SELECT 
    Q.c_customer_id,
    Q.cd_gender,
    Q.ib_income_band_sk,
    Q.total_sales,
    CASE 
        WHEN Q.sales_rank <= 10 THEN 'Top Sales Performer'
        WHEN Q.sales_rank BETWEEN 11 AND 50 THEN 'Average Sales Performer'
        ELSE 'Low Sales Performer'
    END AS performance_category
FROM qualified_customers Q
WHERE Q.total_sales IS NOT NULL
ORDER BY Q.total_sales DESC;
