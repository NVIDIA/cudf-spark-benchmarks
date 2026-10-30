
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_net_profit, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        ca.ca_state, 
        w.w_warehouse_name, 
        d.d_month_seq, 
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
),
AggregatedSales AS (
    SELECT 
        sd.ca_state, 
        sd.cd_gender,
        sd.cd_marital_status,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(*) AS transaction_count
    FROM 
        SalesData sd
    GROUP BY 
        sd.ca_state, sd.cd_gender, sd.cd_marital_status
)
SELECT 
    asd.ca_state, 
    asd.cd_gender, 
    asd.cd_marital_status, 
    asd.total_quantity,
    asd.total_profit,
    ROUND(asd.total_profit / NULLIF(asd.transaction_count, 0), 2) AS avg_profit_per_transaction
FROM 
    AggregatedSales asd
ORDER BY 
    asd.total_profit DESC
LIMIT 50;
