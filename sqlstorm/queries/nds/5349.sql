
WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(ws_item_sk) AS total_sales
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY
        ws_item_sk
),
CustomerData AS (
    SELECT
        c.c_customer_sk,
        d.d_year,
        SUM(COALESCE(sd.total_profit, 0)) AS total_profit_by_customer,
        COUNT(DISTINCT sd.total_orders) AS unique_orders_per_customer
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_item_sk
    WHERE
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY
        c.c_customer_sk, d.d_year
),
ReturnData AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM
        store_returns
    WHERE
        sr_returned_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY
        sr_customer_sk
)
SELECT
    c.c_customer_sk,
    SUM(cd.total_profit_by_customer) AS total_customer_profit,
    AVG(cd.unique_orders_per_customer) AS avg_orders_customer,
    COALESCE(SUM(rd.total_return_amt), 0) AS total_return
FROM
    CustomerData cd
JOIN customer c ON cd.c_customer_sk = c.c_customer_sk
LEFT JOIN ReturnData rd ON c.c_customer_sk = rd.sr_customer_sk
GROUP BY
    c.c_customer_sk
ORDER BY
    total_customer_profit DESC
LIMIT 10;
