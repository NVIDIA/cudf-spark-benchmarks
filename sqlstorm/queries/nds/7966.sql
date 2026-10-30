
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk
), 
High_Value_Customers AS (
    SELECT 
        c_customer_sk
    FROM 
        Customer_Sales
    WHERE 
        total_sales > 10000
), 
Customer_Address AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address AS ca
    JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        c.c_customer_sk IN (SELECT c_customer_sk FROM High_Value_Customers)
)
SELECT 
    cv.ca_city,
    cv.ca_state,
    COUNT(*) AS number_of_customers,
    AVG(cs.total_sales) AS avg_sales,
    SUM(cs.average_profit) AS total_profit
FROM 
    Customer_Address AS cv
JOIN 
    Customer_Sales AS cs ON cs.c_customer_sk IN (SELECT c_customer_sk FROM High_Value_Customers)
GROUP BY 
    cv.ca_city, 
    cv.ca_state
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_profit DESC;
