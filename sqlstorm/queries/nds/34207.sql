
WITH  SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
TopItems AS (
    SELECT
        i.i_item_id,
        COALESCE(s.total_sales, 0) AS total_sales
    FROM
        item i
    LEFT JOIN SalesCTE s ON i.i_item_sk = s.ws_item_sk
    WHERE
        i.i_current_price > 0
),
CustomerIncome AS (
    SELECT
        c.c_customer_sk,
        CASE
            WHEN h.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN h.hd_income_band_sk BETWEEN 1 AND 5 THEN 'Low'
            WHEN h.hd_income_band_sk BETWEEN 6 AND 10 THEN 'Medium'
            ELSE 'High'
        END AS income_level,
        COUNT(DISTINCT o.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    LEFT JOIN web_sales o ON c.c_customer_sk = o.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, h.hd_income_band_sk
),
SalesByIncome AS (
    SELECT
        ci.income_level,
        SUM(t.total_sales) AS total_sales_by_income
    FROM
        CustomerIncome ci
    JOIN TopItems t ON ci.order_count > 0
    GROUP BY
        ci.income_level
)
SELECT
    income_level,
    SUM(total_sales_by_income) AS aggregated_sales,
    COUNT(*) AS customer_count
FROM
    SalesByIncome
GROUP BY
    income_level
ORDER BY
    income_level;

