
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_profit DESC) AS rank
    FROM 
        SalesData sd
    JOIN 
        CustomerDetails cd ON sd.ws_item_sk = cd.c_customer_sk
)
SELECT 
    rs.ws_item_sk,
    rs.c_customer_sk,
    rs.c_first_name,
    rs.c_last_name,
    rs.total_quantity,
    rs.total_sales,
    rs.total_profit
FROM 
    RankedSales rs
WHERE 
    rs.rank <= 5
ORDER BY 
    rs.ws_item_sk, rs.total_profit DESC;
