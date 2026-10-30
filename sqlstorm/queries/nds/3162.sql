
WITH sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws.ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
returns_summary AS (
    SELECT
        cr.cr_item_sk,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_tax) AS total_return_tax
    FROM
        catalog_returns cr
    WHERE
        cr.cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        cr.cr_item_sk
)
SELECT
    si.ws_item_sk,
    si.total_quantity,
    si.total_sales_price,
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    RANK() OVER (ORDER BY si.total_sales_price DESC) AS overall_sales_rank
FROM
    sales_summary si
JOIN
    customer_info ci ON si.ws_item_sk = ci.c_customer_sk
LEFT JOIN
    returns_summary rs ON si.ws_item_sk = rs.cr_item_sk
WHERE
    (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
    AND (total_quantity > 10 OR total_sales_price > 1000)
ORDER BY
    overall_sales_rank, si.total_sales_price DESC;
