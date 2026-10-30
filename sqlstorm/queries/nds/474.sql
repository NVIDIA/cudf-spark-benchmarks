
WITH RecentReturns AS (
    SELECT 
        wr_returned_date_sk,
        COUNT(wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM web_returns
    WHERE wr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY wr_returned_date_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales_value,
        ws_web_site_sk
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_web_site_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    d.d_date AS return_date,
    r.total_web_returns,
    r.total_return_value,
    s.total_quantity_sold,
    s.total_sales_value,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    wi.w_warehouse_name,
    wi.total_inventory
FROM date_dim d
LEFT JOIN RecentReturns r ON r.wr_returned_date_sk = d.d_date_sk
LEFT JOIN SalesData s ON s.ws_sold_date_sk = d.d_date_sk
LEFT JOIN CustomerDemographics cd ON cd.total_customers > 100
LEFT JOIN WarehouseInfo wi ON wi.total_inventory > 1000
WHERE 
    d.d_year = 2023 
    AND (r.total_web_returns IS NOT NULL OR s.total_quantity_sold IS NOT NULL)
ORDER BY d.d_date
LIMIT 100;
