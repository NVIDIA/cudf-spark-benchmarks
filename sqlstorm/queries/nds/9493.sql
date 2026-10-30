
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
SalesDemographics AS (
    SELECT 
        cs.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), 
SalesDate AS (
    SELECT 
        cs.c_customer_sk,
        dd.d_year,
        dd.d_quarter_seq
    FROM 
        CustomerSales cs
    JOIN 
        date_dim dd ON cs.last_purchase_date = dd.d_date_sk
)
SELECT 
    sd.cd_gender,
    sd.cd_marital_status,
    COUNT(DISTINCT sd.c_customer_sk) AS customer_count,
    SUM(cs.total_quantity) AS grand_total_quantity,
    SUM(cs.total_net_profit) AS grand_total_net_profit,
    COUNT(DISTINCT sd.c_customer_sk) AS distinct_customers,
    sd.ib_income_band_sk AS income_band
FROM 
    SalesDemographics sd
JOIN 
    CustomerSales cs ON sd.c_customer_sk = cs.c_customer_sk
JOIN 
    SalesDate sd2 ON sd.c_customer_sk = sd2.c_customer_sk
WHERE 
    sd2.d_year = 2023
GROUP BY 
    sd.cd_gender, 
    sd.cd_marital_status, 
    sd.ib_income_band_sk
ORDER BY 
    grand_total_net_profit DESC;
