WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2459489 AND 2459495  
    GROUP BY
        ws_item_sk
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        SUM(sd.total_sales) AS total_spent,
        COUNT(DISTINCT sd.order_count) AS order_count
    FROM
        customer c
    JOIN
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN
        SalesData sd ON c.c_customer_sk = sd.ws_item_sk   
    GROUP BY
        c.c_customer_sk, d.cd_gender, d.cd_marital_status, d.cd_education_status
),
FinalStats AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c_customer_sk) AS customer_count,
        AVG(total_spent) AS avg_spent,
        SUM(order_count) AS total_orders
    FROM
        CustomerStats
    GROUP BY
        cd_gender, cd_marital_status, cd_education_status
)
SELECT
    cd_gender,
    cd_marital_status,
    cd_education_status,
    customer_count,
    avg_spent,
    total_orders
FROM
    FinalStats
WHERE
    customer_count > 100  
ORDER BY
    avg_spent DESC;