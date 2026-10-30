
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_profit
    FROM 
        SalesData
    WHERE 
        item_rank <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.cd_gender,
    cs.cd_marital_status,
    ts.total_quantity,
    ts.total_profit,
    COALESCE(rs.return_count, 0) AS return_count,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount
FROM 
    CustomerDetails cs
JOIN 
    TopSales ts ON ts.ws_item_sk = ts.ws_item_sk
LEFT JOIN 
    ReturnStats rs ON ts.ws_item_sk = rs.sr_item_sk
ORDER BY 
    ts.total_profit DESC, cs.c_last_name, cs.c_first_name;
