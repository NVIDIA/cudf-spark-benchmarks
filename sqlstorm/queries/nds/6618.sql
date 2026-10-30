
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_name,
    sm.sm_type,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_income_band_sk
FROM
    customer c
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN
    ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    d.d_year BETWEEN 2020 AND 2022
    AND sm.sm_type IN ('EXPRESS', 'STANDARD')
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name,
    d.d_year, d.d_month_seq, w.w_warehouse_name,
    sm.sm_type, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
ORDER BY
    total_sales DESC
LIMIT 100;
