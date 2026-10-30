
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) AS income_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
sales_data AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
), 
returns_data AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    sd.ws_ship_date_sk,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0) AS net_sales,
    RANK() OVER (ORDER BY COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0) DESC) AS sales_rank
FROM 
    customer_info ci
LEFT JOIN 
    sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
LEFT JOIN 
    returns_data rd ON sd.ws_item_sk = rd.sr_item_sk
WHERE 
    ci.income_rank <= 10
GROUP BY 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    sd.ws_ship_date_sk,
    sd.total_sales,
    rd.total_returns,
    rd.total_return_amt,
    ci.income_rank
ORDER BY 
    net_sales DESC
LIMIT 100;
