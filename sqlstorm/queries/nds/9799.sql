
WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        d.d_year AS sale_year,
        d.d_month_seq AS sale_month,
        w.w_warehouse_name
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        ws.ws_sold_date_sk, d.d_year, d.d_month_seq, w.w_warehouse_name
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(sd.total_sales) AS total_sales,
        COUNT(DISTINCT sd.unique_customers) AS unique_customers_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        sales_data sd ON c.c_customer_sk = sd.unique_customers
    GROUP BY
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT
    c.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(cd.total_sales) AS total_sales,
    COUNT(DISTINCT cd.unique_customers_count) AS unique_customers_count,
    RANK() OVER (ORDER BY SUM(cd.total_sales) DESC) AS sales_rank
FROM
    customer_data cd
JOIN
    customer c ON cd.c_customer_sk = c.c_customer_sk
GROUP BY
    c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
HAVING
    SUM(cd.total_sales) > 1000
ORDER BY
    sales_rank;
