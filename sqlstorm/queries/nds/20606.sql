
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
      AND c.c_birth_year IS NOT NULL
      AND ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023
          AND d.d_month_seq IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_year = 2020)
      )
    GROUP BY ws.ws_item_sk
),
returns_data AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns wr
    WHERE EXISTS (
        SELECT 1 
        FROM web_sales ws 
        WHERE ws.ws_item_sk = wr.wr_item_sk 
          AND ws.ws_sold_date_sk BETWEEN 
              (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) AND 
              (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    )
    GROUP BY wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(sd.total_quantity, 0) AS total_sold,
    COALESCE(rd.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(sd.total_quantity, 0) = 0 THEN NULL
        ELSE (COALESCE(rd.total_return_amount, 0) / COALESCE(sd.total_quantity, 1)) * 100 
    END AS return_percentage
FROM item i
LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN returns_data rd ON i.i_item_sk = rd.wr_item_sk
WHERE i.i_current_price > (
      SELECT AVG(i_current_price) 
      FROM item 
      WHERE i_current_price IS NOT NULL
) * 1.1
OR (i.i_size IS NULL AND EXISTS (
      SELECT 1 FROM store s 
      WHERE s.s_number_employees IS NOT NULL AND s.s_city LIKE '%town%'
))
ORDER BY return_percentage DESC NULLS LAST
