
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        dd.d_year,
        dd.d_quarter_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_ship_date_sk = dd.d_date_sk
),
TopProfitableItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.d_year,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.profit_rank <= 5
    GROUP BY 
        sd.ws_item_sk, sd.d_year
),
CustomerPreferences AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_preferred_cust_flag, cd.cd_gender, cd.cd_marital_status
),
ReturnStatistics AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_return_amt
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_profit,
    cp.c_customer_sk,
    cp.c_preferred_cust_flag,
    cp.cd_gender,
    cp.cd_marital_status,
    rs.total_returned,
    rs.total_return_amt
FROM 
    TopProfitableItems ti
JOIN 
    CustomerPreferences cp ON ti.ws_item_sk = cp.c_customer_sk
LEFT JOIN 
    ReturnStatistics rs ON ti.ws_item_sk = rs.cr_item_sk
WHERE 
    (cp.c_preferred_cust_flag = 'Y' OR cp.cd_gender = 'F')
    AND (rs.total_returned IS NULL OR rs.total_returned < 10)
ORDER BY 
    ti.total_net_profit DESC, cp.total_orders DESC
LIMIT 50;
