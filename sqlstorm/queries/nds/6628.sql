
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        ca_county,
        COUNT(DISTINCT c_customer_sk) AS total_customers
    FROM 
        customer_address
    JOIN 
        customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
    GROUP BY 
        ca_county
),
ProfitData AS (
    SELECT 
        SalesData.ws_sold_date_sk,
        SUM(SalesData.total_net_profit) AS total_profit,
        COUNT(DISTINCT CustomerData.total_customers) AS distinct_customers
    FROM 
        SalesData
    JOIN 
        CustomerData ON SalesData.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        SalesData.ws_sold_date_sk
)
SELECT 
    d.d_date AS sale_date,
    pd.total_profit,
    cd.total_customers
FROM 
    date_dim d
LEFT JOIN 
    ProfitData pd ON d.d_date_sk = pd.ws_sold_date_sk
LEFT JOIN 
    CustomerData cd ON d.d_date_sk BETWEEN 2450000 AND 2450600
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date;
