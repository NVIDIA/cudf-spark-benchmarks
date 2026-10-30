WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-07-01' AND '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    COALESCE(s.part_count, 0) AS supplier_part_count,
    r.o_totalprice,
    d.revenue,
    d.total_quantity,
    CASE 
        WHEN r.o_totalprice > 1000 THEN 'High Value'
        WHEN r.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierStats s ON r.o_orderkey = s.s_suppkey
LEFT JOIN 
    OrderDetails d ON r.o_orderkey = d.l_orderkey
WHERE 
    r.order_rank = 1
    AND (s.total_supplycost IS NULL OR s.total_supplycost > 5000)
    AND d.line_item_count > 5
ORDER BY 
    r.o_orderdate DESC;