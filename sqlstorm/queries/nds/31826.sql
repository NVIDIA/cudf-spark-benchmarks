
WITH  sales_totals AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
    HAVING
        SUM(ws_net_profit) > 0

    UNION ALL

    SELECT
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        cs_bill_customer_sk
    HAVING
        SUM(cs_net_profit) > 0
),
aggregated_sales AS (
    SELECT
        customer_sk,
        SUM(total_profit) AS total_profit,
        SUM(total_orders) AS total_orders
    FROM
        sales_totals
    GROUP BY
        customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ag.total_profit,
        ag.total_orders
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        aggregated_sales ag ON c.c_customer_sk = ag.customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ci.total_profit, 0) AS total_profit,
    COALESCE(ci.total_orders, 0) AS total_orders,
    DENSE_RANK() OVER (ORDER BY COALESCE(ci.total_profit, 0) DESC) AS profit_ranking,
    CASE 
        WHEN ci.total_orders IS NULL THEN 'No Orders'
        WHEN ci.total_orders = 0 THEN 'Zero Orders'
        ELSE 'Active Customer'
    END AS order_status
FROM 
    customer_info ci
WHERE 
    ci.cd_gender = 'F'
    AND ci.total_profit > 1000
ORDER BY 
    ci.total_profit DESC
LIMIT 10;
