
WITH  sales_summary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
    HAVING
        SUM(ws_net_paid) > 1000
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
top_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.hd_buy_potential
    FROM
        customer_info ci
    WHERE
        ci.rank <= 5
),
returns_summary AS (
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt
    FROM
        web_returns
    GROUP BY
        wr_returned_date_sk, wr_item_sk
),
final_summary AS (
    SELECT
        s.ws_sold_date_sk,
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        cc.c_first_name,
        cc.c_last_name
    FROM
        sales_summary s
    LEFT JOIN returns_summary r ON s.ws_item_sk = r.wr_item_sk
    LEFT JOIN top_customers cc ON s.ws_item_sk = cc.c_customer_sk
)
SELECT
    d.d_date_id,
    f.ws_item_sk,
    f.total_quantity,
    f.total_sales,
    f.total_returns,
    f.total_return_amt,
    CASE 
        WHEN f.total_sales > 500 THEN 'High'
        WHEN f.total_sales BETWEEN 200 AND 500 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM
    final_summary f
JOIN date_dim d ON f.ws_sold_date_sk = d.d_date_sk
WHERE
    d.d_year = 2023
ORDER BY
    d.d_date_id, f.total_sales DESC;
