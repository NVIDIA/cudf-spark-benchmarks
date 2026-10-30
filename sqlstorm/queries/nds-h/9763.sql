
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RegionsWithSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    rws.r_regionkey,
    rws.r_name,
    rws.supplier_count,
    ro.total_revenue
FROM 
    RegionsWithSuppliers rws
LEFT JOIN 
    RankedOrders ro ON rws.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey 
        WHERE s.s_suppkey = (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey = (
                SELECT p.p_partkey 
                FROM part p 
                ORDER BY p.p_retailprice DESC 
                LIMIT 1
            ) 
            ORDER BY ps.ps_supplycost ASC 
            LIMIT 1
        )
    )
WHERE 
    ro.order_rank = 1
ORDER BY 
    rws.r_regionkey, total_revenue DESC;
