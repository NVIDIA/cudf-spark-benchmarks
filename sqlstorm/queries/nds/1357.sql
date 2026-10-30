
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk IS NOT NULL
),
ItemSummary AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(rs.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(rs.ws_ext_sales_price), 0) AS total_sales
    FROM
        item i
    LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.sales_rank <= 5
    GROUP BY
        i.i_item_sk, i.i_item_desc
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT
    cs.order_count,
    cs.avg_order_value,
    isum.i_item_desc,
    isum.total_quantity,
    isum.total_sales
FROM
    CustomerStats cs
JOIN ItemSummary isum ON cs.order_count > 0
WHERE
    cs.avg_order_value > (
        SELECT
            AVG(avg_order_value) 
        FROM 
            CustomerStats
    )
ORDER BY
    isum.total_sales DESC
LIMIT 10;
