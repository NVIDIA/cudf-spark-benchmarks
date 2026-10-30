
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_city, ca_state
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        SUM(CASE WHEN ws_net_profit < 0 THEN 1 ELSE 0 END) AS negative_profits
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        d_year BETWEEN 2015 AND 2023
    GROUP BY 
        d_year
),
ReturnRates AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesByItem AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ad.ca_city,
    ad.ca_state,
    ad.customer_count,
    ad.female_count,
    ad.male_count,
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(si.total_sold, 0) AS total_sold,
    CASE 
        WHEN ss.total_orders > 0 THEN ROUND((COALESCE(r.total_returns, 0) / ss.total_orders) * 100, 2)
        ELSE NULL
    END AS return_rate_percentage,
    CASE 
        WHEN ss.negative_profits > 0 THEN 'Warning: Negative Profits'
        ELSE 'All Profitable'
    END AS profit_status
FROM 
    AddressDetails ad
JOIN 
    SalesStats ss ON 1=1
LEFT JOIN 
    ReturnRates r ON r.sr_item_sk IN (SELECT ci.i_item_sk FROM item ci JOIN SalesByItem si ON ci.i_item_sk = si.ws_item_sk)
LEFT JOIN 
    SalesByItem si ON si.ws_item_sk IN (SELECT si1.ws_item_sk FROM web_sales si1 WHERE si1.ws_quantity > 0)
ORDER BY 
    ad.ca_state ASC, ad.ca_city ASC, ss.d_year DESC;
