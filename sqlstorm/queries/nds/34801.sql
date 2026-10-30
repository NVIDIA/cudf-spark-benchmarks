
WITH  sales_summary AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk) AS rn
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
), 
items_with_promotions AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        p.p_promo_sk,
        p.p_discount_active,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk
    WHERE 
        p.p_discount_active = 'Y' OR p.p_discount_active IS NULL
    GROUP BY 
        i.i_item_sk, i.i_item_id, p.p_promo_sk, p.p_discount_active
), 
dates AS (
    SELECT 
        d_date_sk,
        d_year,
        d_month_seq,
        d_day_name
    FROM 
        date_dim
    WHERE 
        d_year = 2023
), 
final_summary AS (
    SELECT 
        ds.d_year,
        ds.d_month_seq,
        SUM(ss.total_sales) AS month_sales,
        SUM(iwp.total_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold
    FROM 
        sales_summary ss
    INNER JOIN 
        dates ds ON ss.ss_sold_date_sk = ds.d_date_sk
    LEFT JOIN 
        items_with_promotions iwp ON ss.ss_item_sk = iwp.i_item_sk
    GROUP BY 
        ds.d_year, ds.d_month_seq
)
SELECT 
    fs.d_year,
    fs.d_month_seq,
    fs.month_sales,
    fs.total_profit,
    fs.distinct_items_sold,
    CASE 
        WHEN fs.total_profit IS NULL THEN 'No Profit'
        WHEN fs.month_sales > 10000 THEN 'High Sales'
        ELSE 'Regular Sales'
    END AS sales_category
FROM 
    final_summary fs
WHERE 
    fs.month_sales > 0
ORDER BY 
    fs.d_year, fs.d_month_seq;
