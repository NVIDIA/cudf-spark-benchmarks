
SELECT 
    SUM(ws_net_profit) AS total_net_profit,
    d_year,
    i_category
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
JOIN 
    item ON ws_item_sk = i_item_sk
GROUP BY 
    d_year, i_category
ORDER BY 
    d_year, total_net_profit DESC;
