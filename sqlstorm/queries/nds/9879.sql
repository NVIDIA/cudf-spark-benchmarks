
WITH sales_summary AS (
    SELECT
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        web_sales AS ws
    JOIN
        date_dim AS dd ON ws.ws_ship_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023 AND dd.d_month_seq IN (1, 2, 3)
    GROUP BY
        ws.ws_ship_date_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate > 1000
),
top_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_sales
    FROM
        customer_info AS ci
    JOIN
        sales_summary AS si ON ci.c_customer_sk IN (
            SELECT
                ws_bill_customer_sk
            FROM
                web_sales
            WHERE
                ws_ship_date_sk IN (SELECT ws_ship_date_sk FROM sales_summary)
        )
    ORDER BY
        si.total_sales DESC
    LIMIT 10
)
SELECT
    tc.cd_gender,
    tc.cd_marital_status,
    COUNT(tc.c_customer_sk) AS customer_count,
    SUM(ts.total_sales) AS total_sales_by_gender_marital_status
FROM
    top_customers AS tc
JOIN
    sales_summary AS ts ON ts.ws_ship_date_sk IN (
        SELECT ws_ship_date_sk
        FROM sales_summary
    )
GROUP BY
    tc.cd_gender,
    tc.cd_marital_status
ORDER BY
    total_sales_by_gender_marital_status DESC;
