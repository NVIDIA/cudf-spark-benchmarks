
WITH CustomerStats AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit
    FROM
        customer_demographics cd
    JOIN
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesByWarehouse AS (
    SELECT
        w.w_warehouse_sk,
        SUM(ws.ws_sales_price) AS total_warehouse_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        warehouse w
    JOIN
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY
        w.w_warehouse_sk
),
SalesTrends AS (
    SELECT
        dd.d_year,
        SUM(ws.ws_sales_price) AS total_annual_sales
    FROM
        date_dim dd
    JOIN
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        dd.d_year
)
SELECT
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_customers,
    cs.total_sales,
    cs.average_profit,
    sw.total_warehouse_sales,
    sw.total_orders,
    st.total_annual_sales
FROM
    CustomerStats cs
JOIN
    SalesByWarehouse sw ON cs.cd_demo_sk % 10 = sw.w_warehouse_sk % 10
JOIN
    SalesTrends st ON cs.cd_demo_sk % 5 = st.d_year % 5
ORDER BY
    total_sales DESC, average_profit DESC;
