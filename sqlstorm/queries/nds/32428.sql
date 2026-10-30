
WITH  MonthlySales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        date_dim d
    JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
    
    UNION ALL
    
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM
        date_dim d
    JOIN
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
),
SalesAggregates AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COALESCE(SUM(total_sales), 0) AS monthly_sales
    FROM
        date_dim d
    LEFT JOIN
        MonthlySales ms ON d.d_year = ms.d_year AND d.d_month_seq = ms.d_month_seq
    GROUP BY
        d.d_year, d.d_month_seq
),
CustomerMetrics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender
)
SELECT
    cm.c_customer_sk,
    cm.cd_gender,
    cs.total_sales,
    CASE
        WHEN cm.order_count > 5 THEN 'High Value'
        WHEN cm.order_count BETWEEN 1 AND 5 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category,
    COALESCE(cs.total_sales, 0) AS web_sales_contribution
FROM
    CustomerMetrics cm
LEFT JOIN
    (SELECT d_year, SUM(monthly_sales) AS total_sales
     FROM SalesAggregates
     GROUP BY d_year) cs ON cm.c_customer_sk = cs.d_year
WHERE
    cm.cd_gender IS NOT NULL
ORDER BY
    cm.total_spent DESC NULLS LAST
LIMIT 100;
