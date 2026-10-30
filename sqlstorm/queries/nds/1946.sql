
WITH SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_ship_date_sk,
        ws_web_site_sk,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
AggregatedData AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales_value,
        AVG(sd.ws_sales_price) AS average_sales_price,
        COUNT(*) AS transaction_count
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
    GROUP BY 
        sd.ws_item_sk
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_city
),
FinalReport AS (
    SELECT 
        ad.ws_item_sk,
        ad.total_quantity,
        ad.total_sales_value,
        ad.average_sales_price,
        ca.ca_city,
        ca.customer_count,
        ca.avg_purchase_estimate
    FROM 
        AggregatedData ad
    LEFT JOIN 
        CustomerAddresses ca ON ad.ws_item_sk = ca.c_customer_sk
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_sales_value,
    fr.average_sales_price,
    COALESCE(fr.ca_city, 'Unknown') AS city,
    COALESCE(fr.customer_count, 0) AS customer_count,
    COALESCE(fr.avg_purchase_estimate, 0) AS avg_purchase_estimate
FROM 
    FinalReport fr
WHERE 
    fr.total_sales_value > (SELECT AVG(total_sales_value) FROM AggregatedData)
ORDER BY 
    fr.total_sales_value DESC
LIMIT 100;
