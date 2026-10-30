WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    COALESCE(ls.revenue, 0) AS total_revenue,
    COALESCE(ls.part_count, 0) AS total_parts,
    COALESCE(sc.avg_supplycost, 0) AS avg_supplycost
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemSummary ls ON r.o_orderkey = ls.l_orderkey
LEFT JOIN 
    (SELECT p.p_partkey, s.avg_supplycost 
     FROM part p 
     JOIN SupplierCosts s ON p.p_partkey = s.ps_partkey
     WHERE p.p_retailprice > 100.00) AS sc ON sc.p_partkey = r.o_orderkey
WHERE 
    r.order_rank <= 5
ORDER BY 
    r.o_orderkey;