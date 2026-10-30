
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
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
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq, cd.cd_gender, cd.cd_education_status, ca.ca_city, ca.ca_state
),
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.total_profit DESC) AS rank_by_profit,
        RANK() OVER (PARTITION BY sd.d_year, sd.d_month_seq ORDER BY sd.total_quantity DESC) AS rank_by_quantity
    FROM 
        SalesData sd
)
SELECT 
    d_year,
    d_month_seq,
    rank_by_profit,
    rank_by_quantity,
    total_quantity,
    total_profit,
    cd_gender,
    cd_education_status,
    ca_city,
    ca_state
FROM 
    RankedSales
WHERE 
    rank_by_profit <= 5 OR rank_by_quantity <= 5
ORDER BY 
    d_year, d_month_seq, rank_by_profit, rank_by_quantity;
