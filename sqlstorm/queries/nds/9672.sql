WITH sales_summary AS (
    SELECT
        ws_bill_cdemo_sk AS demo_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2450000 AND 2450600 
    GROUP BY
        ws_bill_cdemo_sk
),
demographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM
        customer_demographics
),
joined_data AS (
    SELECT
        ds.demo_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        ds.total_quantity,
        ds.total_sales,
        ds.avg_net_profit
    FROM
        sales_summary ds
    JOIN
        demographics d ON ds.demo_sk = d.cd_demo_sk
),
warehouse_impact AS (
    SELECT
        w.w_warehouse_name,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY
        w.w_warehouse_name
),
final_summary AS (
    SELECT
        jd.cd_gender,
        jd.cd_marital_status,
        jd.cd_education_status,
        jd.cd_purchase_estimate,
        jd.total_quantity,
        jd.total_sales,
        jd.avg_net_profit,
        wi.total_net_profit
    FROM
        joined_data jd
    JOIN
        warehouse_impact wi ON jd.total_sales > 1000
)
SELECT
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    total_quantity,
    total_sales,
    avg_net_profit,
    total_net_profit
FROM
    final_summary
ORDER BY
    total_sales DESC;