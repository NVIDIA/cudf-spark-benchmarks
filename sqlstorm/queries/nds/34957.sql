
WITH  Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        SUM(ws_net_profit) > 0

    UNION ALL

    SELECT 
        d.d_date_sk,
        SUM(ws_ext_sales_price) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS profit_rank
    FROM 
        date_dim d 
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = (SELECT MAX(d_year) FROM date_dim)
    GROUP BY 
        d.d_date_sk
),

Highest_Profit_Customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_net_profit) AS customer_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS customer_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws_net_profit) > 0
),

Address_Details AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_sales
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
)

SELECT 
    sd.d_date_sk AS ws_sold_date_sk,
    sc.total_profit,
    (SELECT COUNT(*) FROM Highest_Profit_Customers hp WHERE hp.customer_rank <= 10) AS top_customers_count,
    ad.ca_city,
    ad.ca_state,
    ad.total_sales
FROM 
    Sales_CTE sc
LEFT JOIN 
    Address_Details ad ON ad.total_sales > 0
JOIN 
    date_dim sd ON sd.d_date_sk = sc.ws_sold_date_sk
WHERE 
    sc.profit_rank <= 5
ORDER BY 
    sc.total_profit DESC, ad.total_sales DESC
LIMIT 100;
