
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month,
        c.c_birth_year,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        (cd.cd_marital_status = 'S' OR cd.cd_gender = 'F')
    GROUP BY
        c.c_customer_sk, c.c_birth_month, c.c_birth_year, cd.cd_gender
),
MonthlySales AS (
    SELECT
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM
        date_dim d
    LEFT JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY
        d.d_month_seq
),
Summary AS (
    SELECT
        cs.c_birth_month,
        cs.c_birth_year,
        cs.cd_gender,
        cs.total_orders,
        cs.total_profit,
        ms.total_sales,
        ms.total_store_sales,
        (COALESCE(cs.total_profit, 0) + COALESCE(ms.total_sales, 0) + COALESCE(ms.total_store_sales, 0)) AS grand_total
    FROM
        CustomerStats cs
    JOIN
        MonthlySales ms ON cs.c_birth_month = EXTRACT(MONTH FROM DATE '2002-10-01') 
)
SELECT
    c_birth_month,
    c_birth_year,
    cd_gender,
    total_orders,
    total_profit,
    total_sales,
    total_store_sales,
    grand_total
FROM
    Summary
ORDER BY
    grand_total DESC
LIMIT 10;
