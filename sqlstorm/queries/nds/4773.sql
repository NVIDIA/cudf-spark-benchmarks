
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
FilteredSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_orders,
        sd.avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_sales > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT
    ca.ca_city,
    SUM(fs.total_sales) AS total_sales_in_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(fs.avg_net_profit) AS avg_profit_per_item
FROM 
    FilteredSales fs
JOIN 
    customer c ON fs.ws_item_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    CustomerDemographics cm ON cd.cd_demo_sk = cm.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    date_dim dd ON fs.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales_in_city DESC
LIMIT 10;
