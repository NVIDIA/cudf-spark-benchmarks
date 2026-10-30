
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state
),
RankedSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.total_quantity,
        sd.total_net_profit,
        sd.avg_net_paid,
        sd.cd_gender,
        sd.cd_marital_status,
        sd.ca_state,
        RANK() OVER (PARTITION BY sd.ca_state ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM 
        SalesData sd
)
SELECT 
    rs.ca_state, 
    rs.cd_gender, 
    rs.cd_marital_status, 
    SUM(rs.total_quantity) AS state_quantity,
    SUM(rs.total_net_profit) AS state_net_profit,
    AVG(rs.avg_net_paid) AS state_avg_net_paid,
    MAX(rs.profit_rank) AS max_profit_rank
FROM 
    RankedSales rs
WHERE 
    rs.profit_rank <= 5
GROUP BY 
    rs.ca_state, 
    rs.cd_gender, 
    rs.cd_marital_status
ORDER BY 
    state_net_profit DESC, 
    state_quantity DESC;
