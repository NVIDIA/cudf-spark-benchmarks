
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
LineItemDetail AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.rank AS order_rank,
    COALESCE(ld.total_revenue, 0) AS total_revenue,
    COALESCE(ld.line_count, 0) AS line_count,
    ss.total_available,
    ss.avg_supply_cost
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemDetail ld ON r.o_orderkey = ld.l_orderkey
FULL OUTER JOIN 
    SupplierSummary ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_retailprice > 100.00 
        LIMIT 1
    )
WHERE 
    r.rank <= 5 
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;
