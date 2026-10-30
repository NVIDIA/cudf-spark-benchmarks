
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        MIN(ws_sales_price) AS min_sales_price,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_sold_date_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.hd_income_band_sk,
        sd.min_sales_price,
        sd.avg_sales_price,
        sd.total_quantity,
        sd.total_orders,
        sd.total_net_profit
    FROM 
        SalesData sd
    JOIN 
        web_sales ws ON sd.ws_sold_date_sk = ws.ws_sold_date_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    css.c_first_name,
    css.c_last_name,
    css.cd_gender,
    css.hd_income_band_sk,
    css.total_orders,
    css.avg_sales_price,
    css.total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY css.hd_income_band_sk ORDER BY css.total_net_profit DESC) AS rank_within_income_band
FROM 
    SalesSummary css
WHERE 
    css.total_orders > 10
ORDER BY 
    css.hd_income_band_sk, rank_within_income_band
LIMIT 100;
