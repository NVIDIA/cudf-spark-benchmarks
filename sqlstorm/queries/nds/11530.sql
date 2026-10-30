
SELECT 
    count(*) AS total_sales, 
    SUM(ws_net_profit) AS total_net_profit
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
JOIN 
    item ON ws_item_sk = i_item_sk
JOIN 
    customer ON ws_bill_customer_sk = c_customer_sk
WHERE 
    d_year = 2023
    AND i_current_price > 10.00
    AND c_birth_year < 1980
GROUP BY 
    d_month_seq
ORDER BY 
    d_month_seq ASC;
