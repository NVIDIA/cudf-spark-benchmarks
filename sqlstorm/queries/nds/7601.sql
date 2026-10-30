WITH CustomerData AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 1998 AND 2000
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        d.d_year
),
WarehouseData AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_shipped,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM
        warehouse w
    JOIN
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    SUM(cd.total_quantity) AS customer_total_quantity,
    SUM(cd.total_sales) AS customer_total_sales,
    wd.w_warehouse_name,
    wd.total_quantity_shipped,
    wd.total_revenue
FROM
    CustomerData cd
JOIN
    WarehouseData wd ON cd.c_customer_sk % 10 = wd.w_warehouse_sk % 10 
GROUP BY
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    wd.w_warehouse_name,
    wd.total_quantity_shipped,
    wd.total_revenue
ORDER BY
    customer_total_sales DESC,
    customer_total_quantity DESC
LIMIT 50;