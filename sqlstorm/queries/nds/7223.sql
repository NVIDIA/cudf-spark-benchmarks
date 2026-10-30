
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        cd.cd_gender, 
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq
), RankedSales AS (
    SELECT 
        sd.*, 
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_net_profit DESC) AS rank
    FROM 
        SalesData sd
)
SELECT 
    r.ws_item_sk, 
    r.ws_order_number, 
    r.total_quantity, 
    r.total_net_profit, 
    r.cd_gender, 
    r.cd_marital_status, 
    r.d_year, 
    r.d_month_seq
FROM 
    RankedSales r
WHERE 
    r.rank <= 5
ORDER BY 
    r.ws_item_sk, 
    r.total_net_profit DESC;
