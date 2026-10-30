WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_profit,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    COALESCE(sp.total_availqty, 0) AS total_supply_qty,
    ld.net_profit,
    ld.line_count
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (
            SELECT s.s_suppkey 
            FROM supplier s 
            WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
        )
    )
LEFT JOIN 
    LineItemDetails ld ON ld.l_orderkey = r.o_orderkey 
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;