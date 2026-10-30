
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY ws.ws_sales_price DESC) AS dense_sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sales_price IS NOT NULL AND i.i_current_price > 0
),
TopSales AS (
    SELECT
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price
    FROM RankedSales rs
    WHERE rs.sales_rank = 1
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE (cd.cd_gender IS NULL OR cd.cd_gender = 'M')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(ts.ws_sales_price, 0) AS highest_sale_price,
    RANK() OVER (ORDER BY cs.total_spent DESC) AS rank_by_spent
FROM CustomerStats cs
LEFT JOIN TopSales ts ON cs.total_orders > 10 AND cs.c_customer_sk = ts.ws_order_number
WHERE (cs.total_orders > 0 OR cs.total_spent IS NOT NULL OR cs.c_last_name IS NOT NULL)
ORDER BY rank_by_spent, cs.c_first_name;
