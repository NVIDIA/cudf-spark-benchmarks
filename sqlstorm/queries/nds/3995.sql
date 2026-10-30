
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city, ca.ca_state ORDER BY ws.ws_net_profit DESC) AS city_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT MAX(d.d_date_sk) - 30 FROM date_dim d
        ) AND (
            SELECT MAX(d.d_date_sk) FROM date_dim d
        )
),
TopSales AS (
    SELECT 
        sd.ca_city,
        sd.ca_state,
        SUM(sd.ws_quantity) AS total_quantity,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.city_rank <= 10
    GROUP BY 
        sd.ca_city, sd.ca_state
)
SELECT 
    ts.ca_city, 
    ts.ca_state,
    ts.total_quantity,
    ts.avg_sales_price,
    ts.total_net_profit,
    CASE 
        WHEN ts.total_net_profit IS NULL THEN 'No Profit'
        ELSE 'Profitable'
    END AS profit_status
FROM 
    TopSales ts
ORDER BY 
    ts.total_net_profit DESC;
