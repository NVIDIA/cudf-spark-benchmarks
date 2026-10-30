
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        hd.hd_income_band_sk, 
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit
    FROM 
        web_sales ws
    UNION ALL
    SELECT 
        cs.cs_sold_date_sk, 
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_net_profit
    FROM 
        catalog_sales cs
    UNION ALL
    SELECT 
        ss.ss_sold_date_sk, 
        ss.ss_item_sk,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_net_profit
    FROM 
        store_sales ss
),
DailySales AS (
    SELECT 
        d.d_date_sk, 
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales, 
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        date_dim d
    JOIN 
        SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
    GROUP BY 
        d.d_date_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.hd_income_band_sk,
    ci.hd_buy_potential,
    ds.total_sales,
    ds.total_profit
FROM 
    CustomerInfo ci
JOIN 
    DailySales ds ON ci.c_customer_sk = ds.d_date_sk
WHERE 
    ci.cd_gender = 'F' 
ORDER BY 
    ds.total_sales DESC
LIMIT 100;
