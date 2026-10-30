
WITH SalesSummary AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CAST(dd.d_date AS DATE) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
    GROUP BY 
        ws.ws_item_sk, dd.d_date
), 
CustomerSegment AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ib.ib_income_band_sk,
        SUM(ss.total_quantity_sold) AS total_quantity_sold
    FROM 
        SalesSummary ss
    JOIN 
        customer c ON ss.ws_item_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
)
SELECT 
    cs.cd_gender, 
    cs.cd_marital_status, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound, 
    SUM(cs.total_quantity_sold) AS total_quantity_by_segment
FROM 
    CustomerSegment cs
JOIN 
    income_band ib ON cs.ib_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    cs.cd_gender, 
    cs.cd_marital_status, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound
ORDER BY 
    total_quantity_by_segment DESC
LIMIT 10;
