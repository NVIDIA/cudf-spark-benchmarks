
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        cs.cs_item_sk
),
TopItems AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_net_profit > 0
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DemographicAnalysis AS (
    SELECT 
        td.total_quantity,
        td.total_net_profit,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        TopItems td
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk IN (SELECT DISTINCT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_city = 'Los Angeles'))
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    COUNT(*) AS customer_count,
    SUM(da.total_quantity) AS total_quantity_sold,
    SUM(da.total_net_profit) AS total_net_profit
FROM 
    DemographicAnalysis da
GROUP BY 
    da.cd_gender, da.cd_marital_status
ORDER BY 
    total_net_profit DESC;
