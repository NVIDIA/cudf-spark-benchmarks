
WITH  sales_performance AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        ws.ws_item_sk
    UNION ALL
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM
        catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        cs.cs_item_sk
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'M') AS gender,
        d.d_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        c.c_customer_sk, cd.cd_gender, d.d_year
)
SELECT
    cs.c_customer_sk,
    cs.gender,
    cs.d_year,
    cs.total_orders,
    cs.total_profit,
    sp.total_quantity,
    sp.total_sales,
    CASE 
        WHEN cs.total_orders = 0 THEN NULL
        ELSE (cs.total_profit / NULLIF(cs.total_orders, 0))
    END AS avg_profit_per_order,
    RANK() OVER (PARTITION BY cs.gender ORDER BY cs.total_profit DESC) AS profit_rank
FROM
    customer_summary cs
LEFT JOIN sales_performance sp ON cs.c_customer_sk = sp.ws_item_sk
WHERE
    (cs.total_orders > 5 OR cs.total_profit > 1000)
ORDER BY
    cs.gender, profit_rank;
