
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        ca.ca_state,
        RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS customer_rank
    FROM
        customer c
    JOIN
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        d.cd_purchase_estimate > 50000
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.cd_gender, d.cd_marital_status, ca.ca_state
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT
    ci.customer_rank,
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_state,
    ss.total_orders,
    ss.total_profit,
    ss.avg_sales_price
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesSummary ss ON ci.customer_rank = 1 
WHERE 
    ci.customer_rank <= 10
ORDER BY 
    ss.total_profit DESC
LIMIT 10;
