
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS total_web_sales_quantity,
        SUM(CASE WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_quantity ELSE 0 END) AS total_store_sales_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales_profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
customer_ranking AS (
    SELECT 
        cs.*,
        RANK() OVER (ORDER BY (total_web_sales_profit + total_store_sales_profit) DESC) AS customer_rank
    FROM customer_summary cs
)
SELECT 
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    cr.cd_marital_status,
    cr.cd_education_status,
    cr.cd_purchase_estimate,
    cr.total_web_sales_quantity,
    cr.total_store_sales_quantity,
    cr.total_web_sales_profit,
    cr.total_store_sales_profit,
    ms.d_year,
    ms.d_month_seq,
    ms.total_web_sales,
    ms.total_store_sales,
    cr.customer_rank
FROM customer_ranking cr
JOIN monthly_sales ms ON cr.cd_purchase_estimate BETWEEN (SELECT MIN(ib_lower_bound) FROM income_band) AND (SELECT MAX(ib_upper_bound) FROM income_band)
WHERE cr.customer_rank <= 100;
