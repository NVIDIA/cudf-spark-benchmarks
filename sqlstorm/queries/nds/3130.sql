
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 
        AND ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
store_info AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        STRING_AGG(DISTINCT CAST(ss.ss_promo_sk AS STRING), ',') AS promo_skus
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk
)
SELECT 
    cu.c_customer_sk,
    cu.cd_gender,
    SUM(s.total_quantity) AS total_purchased_quantity,
    MAX(s.total_sales) AS highest_sales_value,
    COUNT(DISTINCT st.s_store_sk) AS number_of_stores_shopped,
    AVG(COALESCE(s.total_sales, 0)) AS avg_sales_value,
    CASE 
        WHEN COUNT(s.total_sales) > 0 THEN 'Active Customer'
        ELSE 'Inactive Customer'
    END AS customer_status,
    st.promo_skus
FROM customer_info cu
LEFT JOIN ranked_sales s ON cu.c_customer_sk = s.ws_item_sk
LEFT JOIN store_info st ON cu.c_customer_sk = st.s_store_sk
GROUP BY cu.c_customer_sk, cu.cd_gender, st.promo_skus
HAVING SUM(s.total_quantity) IS NOT NULL AND COUNT(st.s_store_sk) > 0
ORDER BY highest_sales_value DESC;
