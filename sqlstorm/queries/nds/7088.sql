WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk AS sales_date,
        ws.ws_item_sk,
        sum(ws.ws_sales_price) AS total_sales,
        sum(ws.ws_quantity) AS total_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        w.w_warehouse_id
    FROM
        web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2451000 AND 2451600 
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        w.w_warehouse_id
),
purchase_trends AS (
    SELECT
        sales_date,
        count(DISTINCT ws_item_sk) AS unique_item_count,
        avg(total_sales) AS avg_sales,
        avg(total_quantity) AS avg_quantity,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ca_city,
        ca_state,
        w_warehouse_id
    FROM
        sales_data
    GROUP BY
        sales_date,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ca_city,
        ca_state,
        w_warehouse_id
),
ranked_trends AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY avg_sales DESC) AS sales_rank
    FROM
        purchase_trends
)
SELECT
    pt.sales_date,
    pt.unique_item_count,
    pt.avg_sales,
    pt.avg_quantity,
    pt.cd_gender,
    pt.cd_marital_status,
    pt.cd_education_status,
    pt.ca_city,
    pt.ca_state,
    pt.w_warehouse_id,
    rt.sales_rank
FROM
    purchase_trends pt
JOIN ranked_trends rt ON pt.sales_date = rt.sales_date
                     AND pt.cd_gender = rt.cd_gender
WHERE
    rt.sales_rank <= 10;