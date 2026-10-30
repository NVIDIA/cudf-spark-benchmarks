
WITH customer_analysis AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        SUM(s.ss_ext_sales_price) AS total_sales_amount,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id, 
        ca.ca_city, 
        cd.cd_gender, 
        cd.cd_marital_status
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ca.ca_city,
    ca.cd_gender,
    ca.cd_marital_status,
    ca.total_sales,
    ca.total_sales_amount,
    ca.avg_purchase_estimate,
    ca.total_web_returns,
    ca.total_returned_amount,
    ws.total_sales_amount AS warehouse_sales_amount,
    ws.total_orders AS warehouse_total_orders
FROM 
    customer_analysis ca
JOIN warehouse_sales ws ON ca.total_sales_amount > ws.total_sales_amount
ORDER BY 
    ca.total_sales_amount DESC, 
    ws.total_sales_amount ASC
LIMIT 100;
