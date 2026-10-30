
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        ib.ib_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ws.ws_item_sk, d.d_year, c.c_current_cdemo_sk, cd.cd_gender, ib.ib_income_band_sk
)
SELECT 
    sd.ws_item_sk,
    sd.d_year,
    COUNT(DISTINCT sd.c_current_cdemo_sk) AS num_customers,
    SUM(sd.total_quantity) AS total_sales_quantity,
    AVG(sd.total_sales) AS avg_sale_price,
    AVG(sd.total_profit) AS avg_profit,
    MAX(sd.total_sales) AS max_sale,
    MIN(sd.total_sales) AS min_sale,
    sd.cd_gender,
    sd.ib_income_band_sk
FROM 
    SalesData sd
GROUP BY 
    sd.ws_item_sk, sd.d_year, sd.cd_gender, sd.ib_income_band_sk
ORDER BY 
    sd.d_year DESC, total_sales_quantity DESC
LIMIT 100;
