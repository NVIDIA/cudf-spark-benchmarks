
WITH sales_summary AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws.ws_list_price) AS average_list_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_gender = 'F'  
        AND cd.cd_marital_status = 'S'  
    GROUP BY
        ws.ws_sold_date_sk
),
store_summary AS (
    SELECT
        ss.ss_sold_date_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid_inc_tax) AS total_revenue,
        AVG(ss.ss_list_price) AS average_list_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_count
    FROM
        store_sales ss
    JOIN
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_gender = 'F'  
        AND cd.cd_marital_status = 'S'  
    GROUP BY
        ss.ss_sold_date_sk
)
SELECT
    COALESCE(ws.ws_sold_date_sk, ss.ss_sold_date_sk) AS sales_date,
    COALESCE(ws.total_quantity, 0) AS web_sales_quantity,
    COALESCE(ws.total_revenue, 0) AS web_sales_revenue,
    COALESCE(ws.average_list_price, 0) AS web_average_price,
    COALESCE(ws.order_count, 0) AS web_order_count,
    COALESCE(ss.total_quantity, 0) AS store_sales_quantity,
    COALESCE(ss.total_revenue, 0) AS store_sales_revenue,
    COALESCE(ss.average_list_price, 0) AS store_average_price,
    COALESCE(ss.order_count, 0) AS store_order_count
FROM
    sales_summary ws
FULL OUTER JOIN
    store_summary ss ON ws.ws_sold_date_sk = ss.ss_sold_date_sk
ORDER BY
    sales_date;
