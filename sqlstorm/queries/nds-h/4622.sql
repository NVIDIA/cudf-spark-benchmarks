
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
LineItemAggregated AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= CURRENT_DATE - INTERVAL '30 DAY'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_totalprice,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    l.item_count,
    ss.unique_parts,
    ss.total_supplycost
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemAggregated l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.s_nationkey = (
        SELECT 
            n.n_nationkey 
        FROM 
            nation n 
        JOIN 
            supplier s ON n.n_nationkey = s.s_nationkey 
        WHERE 
            s.s_suppkey = (
                SELECT 
                    ps.ps_suppkey 
                FROM 
                    partsupp ps 
                WHERE 
                    ps.ps_partkey = (SELECT p.p_partkey FROM part p ORDER BY p.p_retailprice DESC LIMIT 1)
                LIMIT 1
            )
    )
WHERE 
    r.rnk = 1
ORDER BY 
    r.o_totalprice DESC
LIMIT 100;
