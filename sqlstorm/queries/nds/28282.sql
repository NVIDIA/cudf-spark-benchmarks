
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
DemoGenderCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demo_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        i_item_id, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS sales_count
    FROM 
        web_sales
    JOIN 
        item ON web_sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        i_item_id
),
CombinedData AS (
    SELECT 
        ac.ca_city,
        dc.cd_gender,
        ss.total_sales,
        ss.sales_count,
        ac.address_count
    FROM 
        AddressCounts ac
    JOIN 
        DemoGenderCounts dc ON 1=1
    LEFT JOIN 
        SalesSummary ss ON ss.total_sales > 0
)

SELECT 
    ca_city,
    cd_gender,
    SUM(total_sales) AS total_sales,
    SUM(sales_count) AS total_sales_count,
    MAX(address_count) AS max_address_count
FROM 
    CombinedData
GROUP BY 
    ca_city, cd_gender
ORDER BY 
    total_sales DESC, 
    total_sales_count DESC;
