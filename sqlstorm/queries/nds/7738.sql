
WITH SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND i.i_brand = 'BrandX'
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),

CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)

SELECT 
    ss.ws_sold_date_sk,
    ss.ws_item_sk,
    demographics.cd_gender,
    demographics.cd_marital_status,
    demographics.cd_education_status,
    demographics.hd_income_band_sk,
    ss.total_quantity,
    ss.total_sales,
    ss.total_tax,
    ss.total_orders,
    ss.avg_profit
FROM 
    SalesSummary ss
JOIN 
    CustomerDemographics demographics ON ss.ws_item_sk IN (
        SELECT cr.cr_item_sk FROM catalog_returns cr WHERE cr.cr_return_quantity > 0
    )
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
