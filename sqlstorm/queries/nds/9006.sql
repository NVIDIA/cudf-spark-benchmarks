
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state,
        i.i_category
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year = 2023
        AND ws.ws_net_profit > 0
),
ProfitSummary AS (
    SELECT 
        d_year,
        d_month_seq,
        d_quarter_seq,
        ca_state,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_item_sk) AS items_sold,
        AVG(ws_quantity) AS avg_quantity_sold
    FROM 
        SalesData
    GROUP BY 
        d_year, d_month_seq, d_quarter_seq, ca_state, cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    d_year,
    d_month_seq,
    d_quarter_seq,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_profit,
    items_sold,
    avg_quantity_sold,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS ranking
FROM 
    ProfitSummary
ORDER BY 
    d_year, total_profit DESC;
