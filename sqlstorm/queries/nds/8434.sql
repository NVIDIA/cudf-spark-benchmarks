
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
Top_Customers AS (
    SELECT 
        rc.c_customer_sk, 
        rc.c_first_name, 
        rc.c_last_name, 
        rc.cd_gender, 
        rc.cd_marital_status, 
        rc.total_net_profit
    FROM 
        Ranked_Customers rc
    WHERE 
        rc.rank <= 10
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.cd_gender,
    t.cd_marital_status,
    t.total_net_profit,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(ca.ca_state, 'Unknown') AS state,
    COALESCE(w.w_warehouse_name, 'N/A') AS warehouse_name
FROM 
    Top_Customers t
LEFT JOIN 
    customer_address ca ON t.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    warehouse w ON ca.ca_address_sk = w.w_warehouse_sk
ORDER BY 
    t.total_net_profit DESC;
