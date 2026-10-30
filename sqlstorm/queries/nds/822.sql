WITH SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_month = '1') 
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c_customer_sk, 
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        rank() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        CustomerData cd
    JOIN 
        customer c ON cd.c_customer_sk = c.c_customer_sk
    WHERE 
        cd.purchase_rank <= 10 
),
ReturnStats AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    sd.ws_sold_date_sk,
    sd.ws_item_sk,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_profit, 0) AS total_profit,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_purchase_estimate,
    rs.total_returns,
    rs.total_return_amount
FROM 
    SalesData sd
LEFT JOIN 
    TopCustomers tc ON sd.ws_item_sk = tc.c_customer_sk 
LEFT JOIN 
    ReturnStats rs ON sd.ws_item_sk = rs.wr_item_sk
WHERE 
    (sd.total_profit > 1000 OR rs.total_returns IS NOT NULL)
ORDER BY 
    total_profit DESC, 
    sd.ws_sold_date_sk DESC;