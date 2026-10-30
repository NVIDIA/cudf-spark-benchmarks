
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        cd.cd_gender,
        hd.hd_income_band_sk,
        RANK() OVER (PARTITION BY cd.cd_gender, hd.hd_income_band_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_order_number, cd.cd_gender, hd.hd_income_band_sk
), TopSales AS (
    SELECT 
        sales_rank, 
        cd_gender AS gender, 
        hd_income_band_sk AS income_band_sk, 
        total_quantity, 
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    ts.gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(ts.total_quantity) AS total_quantity,
    SUM(ts.total_sales) AS total_sales
FROM 
    TopSales ts
JOIN 
    income_band ib ON ts.income_band_sk = ib.ib_income_band_sk
GROUP BY 
    ts.gender, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    ts.gender, total_sales DESC;
