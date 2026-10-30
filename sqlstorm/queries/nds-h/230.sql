WITH DiscountedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_after_discount,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
        AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ds.total_after_discount,
        ds.unique_parts,
        RANK() OVER (ORDER BY ds.total_after_discount DESC) AS order_rank
    FROM 
        orders o
    LEFT JOIN 
        DiscountedSales ds ON o.o_orderkey = ds.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
)
SELECT 
    o.o_orderkey,
    o.o_totalprice,
    COALESCE(ds.total_after_discount, 0) AS total_after_discount,
    COALESCE(ds.unique_parts, 0) AS unique_parts,
    CASE 
        WHEN ds.order_rank IS NULL THEN 'Not Ranked'
        WHEN ds.order_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS ranking_category
FROM 
    orders o
LEFT JOIN 
    TopOrders ds ON o.o_orderkey = ds.o_orderkey
WHERE 
    o.o_orderdate = (SELECT MAX(o_orderdate) FROM orders)
ORDER BY 
    o.o_orderkey;