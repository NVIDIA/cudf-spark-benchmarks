
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_paid DESC) AS rn
    FROM 
        catalog_sales cs 
    WHERE 
        cs.cs_sold_date_sk BETWEEN 2450203 AND 2450204
),
TotalSales AS (
    SELECT 
        sd.cs_item_sk,
        SUM(sd.cs_quantity) AS total_quantity,
        SUM(sd.cs_ext_sales_price) AS total_sales_price
    FROM 
        SalesData sd
    GROUP BY 
        sd.cs_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_dep_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ts.total_quantity,
    ts.total_sales_price,
    COALESCE(cr.total_returned, 0) AS total_returns,
    cd.cd_gender,
    COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count
FROM 
    item i
LEFT JOIN 
    TotalSales ts ON i.i_item_sk = ts.cs_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
JOIN 
    CustomerDemographics cd ON cd.hd_income_band_sk IN 
    (SELECT ib.ib_income_band_sk FROM income_band ib WHERE ib.ib_upper_bound >= 50000)
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item)
GROUP BY 
    i.i_item_id, i.i_product_name, ts.total_quantity, ts.total_sales_price, cr.total_returned, cd.cd_gender
HAVING 
    COUNT(DISTINCT cd.cd_demo_sk) > 5
ORDER BY 
    ts.total_sales_price DESC
LIMIT 100;
