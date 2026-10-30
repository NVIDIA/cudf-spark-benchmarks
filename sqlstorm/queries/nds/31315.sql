WITH  SalesData AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk, ws_order_number
),
TopSales AS (
    SELECT
        ws_item_sk,
        total_sales,
        order_count
    FROM
        SalesData
    WHERE
        sales_rank <= 10
),
CustomerStat AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(ws.ws_order_number) AS number_of_orders,
        MAX(c.c_birth_year) AS last_year_of_birth 
    FROM
        customer AS c
    LEFT JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_profit,
    cs.number_of_orders,
    ts.total_sales AS top_sales
FROM
    CustomerStat AS cs
LEFT OUTER JOIN
    TopSales AS ts ON cs.c_customer_sk = ts.ws_item_sk
WHERE
    cs.total_profit > (SELECT AVG(total_profit) FROM CustomerStat)
ORDER BY
    cs.total_profit DESC
LIMIT 50;