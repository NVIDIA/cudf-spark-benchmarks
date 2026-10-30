
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        s.ss_sold_date_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_ext_sales_price) AS total_sales,
        SUM(s.ss_ext_discount_amt) AS total_discount,
        SUM(s.ss_net_profit) AS total_profit,
        sd.cd_gender,
        sd.cd_marital_status,
        dd.d_year,
        dd.d_month_seq
    FROM store_sales s
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics sd ON c.c_current_cdemo_sk = sd.cd_demo_sk
    JOIN date_dim dd ON s.ss_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year >= 2019 AND dd.d_year <= 2023
    GROUP BY 
        c.c_customer_id,
        s.ss_sold_date_sk,
        sd.cd_gender,
        sd.cd_marital_status,
        dd.d_year,
        dd.d_month_seq
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM sales_summary
)
SELECT 
    r.c_customer_id,
    r.d_year,
    r.d_month_seq,
    r.total_quantity,
    r.total_sales,
    r.total_discount,
    r.total_profit,
    r.cd_gender,
    r.cd_marital_status
FROM ranked_sales r
WHERE r.sales_rank <= 10
ORDER BY r.d_year, r.d_month_seq, r.total_sales DESC;
