
WITH sales_data AS (
    SELECT
        d.d_year,
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        d.d_year,
        sm.sm_type
),
customer_data AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales
    FROM
        sales_data sd
        JOIN customer c ON sd.total_quantity > 0 AND c.c_customer_sk = sd.total_quantity
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    AVG(cd.total_quantity) AS avg_quantity,
    AVG(cd.total_sales) AS avg_sales,
    COUNT(*) AS customer_count
FROM
    customer_data cd
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY
    avg_sales DESC,
    avg_quantity DESC
LIMIT 10;
