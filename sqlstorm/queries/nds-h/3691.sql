WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        COUNT(DISTINCT li.l_partkey) AS unique_parts
    FROM 
        RankedOrders ro
    JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE 
        ro.rank_order <= 5
    GROUP BY 
        ro.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    nz.total_avail_qty,
    nz.avg_supply_cost,
    COALESCE(hv.unique_parts, 0) AS order_part_count
FROM 
    part p
LEFT JOIN 
    SupplierParts nz ON p.p_partkey = nz.ps_partkey
LEFT JOIN 
    HighValueOrders hv ON hv.o_orderkey IN (
        SELECT 
            o.o_orderkey
        FROM 
            orders o
        WHERE 
            o.o_totalprice > 5000
    )
WHERE 
    p.p_retailprice BETWEEN 100 AND 500
ORDER BY 
    p.p_partkey;