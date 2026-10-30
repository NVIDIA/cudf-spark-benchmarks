
WITH SalesSummary AS (
    SELECT
        ws.ws_sold_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_sales_price - ws.ws_ext_discount_amt) AS net_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        ws.ws_sold_date_sk
),
CustomerSummary AS (
    SELECT
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(c.c_birth_year) AS total_birth_year,
        CASE
            WHEN MAX(cd.cd_credit_rating) IS NULL THEN 'Unknown'
            ELSE MAX(cd.cd_credit_rating)
        END AS max_credit_rating
    FROM
        customer_demographics cd
    JOIN
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY
        cd.cd_demo_sk
)
SELECT
    ss.ws_sold_date_sk,
    ss.total_orders,
    ss.total_sales,
    ss.avg_sales_price,
    ss.net_sales,
    ss.total_profit,
    cs.customer_count,
    cs.total_birth_year,
    cs.max_credit_rating,
    COALESCE((SELECT MAX(ws.ws_sales_price) FROM web_sales ws WHERE ws.ws_sold_date_sk = ss.ws_sold_date_sk), 0) AS max_sales_price
FROM
    SalesSummary ss
LEFT JOIN
    CustomerSummary cs ON cs.cd_demo_sk = (SELECT cd.cd_demo_sk FROM customer c JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk LIMIT 1)
ORDER BY
    ss.ws_sold_date_sk DESC;
