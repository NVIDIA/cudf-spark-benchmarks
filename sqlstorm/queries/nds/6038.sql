
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458855 AND 2458921 
    GROUP BY 
        ws_item_sk
),
CustomerStats AS (
    SELECT 
        cd_demo_sk,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_customer_sk) AS unique_customers
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk 
    GROUP BY 
        cd_demo_sk
),
ItemInfo AS (
    SELECT 
        i_item_sk,
        i_brand,
        i_category,
        i_current_price
    FROM 
        item
),
SalesSummary AS (
    SELECT 
        sd.ws_item_sk,
        ii.i_brand,
        ii.i_category,
        sd.total_quantity,
        sd.total_sales,
        cs.avg_purchase_estimate,
        cs.unique_customers
    FROM 
        SalesData sd
    JOIN 
        ItemInfo ii ON sd.ws_item_sk = ii.i_item_sk
    LEFT JOIN 
        CustomerStats cs ON cs.cd_demo_sk IN (
            SELECT DISTINCT c_current_cdemo_sk 
            FROM customer 
            WHERE c_current_addr_sk IN (
                SELECT ca_address_sk 
                FROM customer_address 
                WHERE ca_state = 'CA'
            )
        ) 
)
SELECT 
    i_brand,
    i_category,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_sales) AS total_sales_amount,
    AVG(avg_purchase_estimate) AS avg_customer_purchase_estimate,
    COUNT(DISTINCT unique_customers) AS total_unique_customers
FROM 
    SalesSummary
GROUP BY 
    i_brand, i_category
ORDER BY 
    total_sales_amount DESC 
LIMIT 10;
