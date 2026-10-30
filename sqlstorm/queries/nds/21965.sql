
WITH CustomerProfit AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > 10000
),
AddressDetails AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country = 'USA'
),
SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_sales_price - ws.ws_net_paid) / NULLIF(COUNT(ws.ws_order_number), 0) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    cp.c_customer_id,
    ad.full_address,
    ss.total_sales,
    ss.avg_discount,
    cp.order_count,
    CASE
        WHEN cp.total_profit IS NULL THEN 'No Profit'
        WHEN cp.total_profit > 50000 THEN 'High Profit'
        ELSE 'Moderate Profit'
    END AS profit_category
FROM 
    CustomerProfit cp
JOIN 
    AddressDetails ad ON cp.c_customer_id = ad.ca_address_id 
JOIN 
    SalesSummary ss ON ss.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2001 AND d.d_dow = 1)
WHERE 
    cp.profit_rank <= 10
ORDER BY 
    ss.total_sales DESC, 
    cp.total_profit DESC
LIMIT 10 OFFSET 0;
