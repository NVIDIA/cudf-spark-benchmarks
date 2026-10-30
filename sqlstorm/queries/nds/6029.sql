
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459585 AND 2459585 + 30 
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        id.ib_lower_bound,
        id.ib_upper_bound
    FROM 
        item i
    JOIN 
        income_band id ON i.i_item_sk = id.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        id.i_product_name,
        id.i_brand,
        id.i_category,
        sd.total_sales,
        sd.total_profit,
        sd.total_orders,
        CASE
            WHEN sd.total_sales >= 10000 THEN 'High'
            WHEN sd.total_sales BETWEEN 5000 AND 9999 THEN 'Medium'
            ELSE 'Low'
        END AS sales_band
    FROM 
        SalesData sd
    JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_sk
)
SELECT 
    s.i_product_name,
    s.i_brand,
    s.i_category,
    s.total_sales,
    s.total_profit,
    s.total_orders,
    s.sales_band,
    COUNT(DISTINCT ca.ca_address_sk) AS unique_customer_addresses,
    AVG(cc.cc_employees) AS avg_call_center_employees
FROM 
    SalesSummary s
LEFT JOIN 
    customer_address ca ON s.total_orders > 0 
LEFT JOIN 
    call_center cc ON s.total_orders > 10 
GROUP BY 
    s.i_product_name, s.i_brand, s.i_category, s.total_sales, s.total_profit, s.total_orders, s.sales_band
ORDER BY 
    s.total_profit DESC
LIMIT 50;
