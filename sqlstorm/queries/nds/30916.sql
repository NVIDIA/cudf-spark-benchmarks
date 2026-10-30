
WITH  SalesByDate AS (
    SELECT
        d.d_date_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales
    FROM
        date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY
        d.d_date_id
    UNION ALL
    SELECT
        d.d_date_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales
    FROM
        date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        d.d_date_id
),
RankedSales AS (
    SELECT
        d.d_month_seq,
        d.d_year,
        SUM(s.total_sales) AS monthly_sales,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(s.total_sales) DESC) AS sales_rank
    FROM
        SalesByDate s
    JOIN date_dim d ON s.d_date_id = d.d_date_id
    GROUP BY
        d.d_month_seq, d.d_year
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.monthly_sales,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Month'
        WHEN r.sales_rank <= 3 THEN 'Top 3 Month'
        ELSE 'Other'
    END AS sales_category
FROM
    RankedSales r
WHERE
    r.sales_rank <= 3
ORDER BY
    r.d_year, r.d_month_seq;
