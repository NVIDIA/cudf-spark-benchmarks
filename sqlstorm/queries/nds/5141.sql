
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        d.d_year,
        i.i_brand_id,
        i.i_category_id,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.ws_item_sk, d.d_year, i.i_brand_id, i.i_category_id, ca.ca_state
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year, i_brand_id ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    d_year,
    i_brand_id,
    ca_state,
    total_quantity,
    total_net_paid,
    total_net_profit
FROM 
    RankedSales
WHERE 
    profit_rank <= 10
ORDER BY 
    d_year, i_brand_id, total_net_profit DESC;
