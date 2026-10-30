WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2458586 AND 2458986 
    GROUP BY
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cs.total_spent,
        cs.order_count
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        RankedSales AS cs ON c.c_customer_sk = cs.ws_bill_customer_sk
    WHERE
        cs.rank <= 10 
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_credit_rating,
    cd.cd_dep_count,
    cd.total_spent,
    cd.order_count,
    w.w_warehouse_name,
    sm.sm_type
FROM
    CustomerDetails AS cd
JOIN
    web_sales AS ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN
    ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY
    cd.total_spent DESC;