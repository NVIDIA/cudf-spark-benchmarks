
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.w_warehouse_id, sm.sm_ship_mode_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
ReturnsSummary AS (
    SELECT 
        SUM(sr.sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
)
SELECT 
    cd.cd_gender AS customer_gender,
    cd.cd_marital_status AS marital_status,
    sales.w_warehouse_id AS wh_id,
    sales.sm_ship_mode_id AS ship_mode,
    COALESCE(sales.total_quantity, 0) AS total_quantity_sold,
    COALESCE(sales.total_profit, 0) AS total_profit,
    rs.total_returned_quantity,
    rs.total_returns
FROM 
    CustomerDemographics cd
    LEFT JOIN SalesData sales ON cd.cd_demo_sk IN (
        SELECT DISTINCT ws.ws_bill_cdemo_sk FROM web_sales ws
    )
    CROSS JOIN ReturnsSummary rs
WHERE 
    cd.customer_count > 50
ORDER BY 
    total_profit DESC, total_quantity_sold DESC;
