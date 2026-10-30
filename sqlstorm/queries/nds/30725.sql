
WITH  SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_moy IN (6, 7)
        )
    GROUP BY
        ws_item_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate > 1000
),
TopSales AS (
    SELECT
        s.ws_item_sk,
        ss_total.total_quantity,
        ss_total.total_sales,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender
    FROM
        SalesCTE s
    JOIN CustomerDetails c ON s.ws_item_sk = c.c_customer_sk
    JOIN (
        SELECT
            ws_item_sk,
            SUM(ws_quantity) AS total_quantity,
            SUM(ws_net_paid) AS total_sales
        FROM
            web_sales
        GROUP BY
            ws_item_sk
    ) ss_total ON s.ws_item_sk = ss_total.ws_item_sk
    WHERE
        s.sales_rank <= 10
)
SELECT
    t.ws_item_sk,
    t.total_quantity,
    t.total_sales,
    COALESCE(CONCAT(t.c_first_name, ' ', t.c_last_name), 'Anonymous') AS customer_name,
    t.cd_gender,
    CASE
        WHEN t.total_sales > 1500 THEN 'High Value'
        WHEN t.total_sales BETWEEN 500 AND 1500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM
    TopSales t
LEFT JOIN
    store s ON t.ws_item_sk = s.s_store_sk
ORDER BY
    t.total_sales DESC;
