
WITH Recursive_CTE AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year, c.c_birth_month) AS rn
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
Aggregated_Sales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
),
Filtered_Customers AS (
    SELECT
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.ca_city,
        r.ca_state,
        a.total_sales,
        a.order_count,
        a.avg_profit
    FROM
        Recursive_CTE r
    JOIN
        Aggregated_Sales a ON r.c_customer_sk = a.ws_bill_customer_sk
    WHERE
        r.rn = 1 
        AND r.hd_income_band_sk IS NOT NULL
        AND (r.ca_state IN ('CA', 'TX') OR a.total_sales > 500)
)
SELECT
    f.c_first_name,
    f.c_last_name,
    f.ca_city,
    f.ca_state,
    COALESCE(f.total_sales, 0) AS total_sales,
    COALESCE(f.order_count, 0) AS order_count,
    COALESCE(f.avg_profit, 0.00) AS avg_profit,
    CASE
        WHEN f.total_sales > 1000 THEN 'High'
        WHEN f.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM
    Filtered_Customers f
ORDER BY
    f.total_sales DESC;
