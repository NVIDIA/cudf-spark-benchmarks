
WITH  sales_trend AS (
    SELECT
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws_ext_sales_price) DESC) as rank
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
), customer_stats AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
        MAX(cd.cd_credit_rating) AS highest_credit_rating
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
), store_summary AS (
    SELECT
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_store_sales,
        AVG(ss_net_profit) AS average_profit
    FROM
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        s.s_store_name
)
SELECT
    s.s_store_name,
    s.total_store_sales,
    s.average_profit,
    cs.customer_count,
    cs.average_purchase_estimate,
    ct.total_sales,
    CTD.d_year
FROM
    store_summary s
JOIN
    customer_stats cs ON cs.customer_count > 0
JOIN
    (SELECT *, ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS trend_rank
     FROM sales_trend) ct ON ct.trend_rank <= 10
JOIN
    date_dim CTD ON CTD.d_year = ct.d_year
WHERE
    s.total_store_sales > (SELECT AVG(total_store_sales) FROM store_summary)
ORDER BY
    s.total_store_sales DESC;
