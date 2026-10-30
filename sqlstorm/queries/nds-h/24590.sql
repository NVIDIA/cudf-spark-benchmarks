WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_returnflag = 'N' AND 
        l.l_discount BETWEEN 0.05 AND 0.15
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.total_quantity * s.s_acctbal) AS supplier_value
    FROM 
        SupplierParts ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.total_quantity * s.s_acctbal) > 100000
)
SELECT 
    n.n_name,
    COALESCE(SUM(ho.o_totalprice), 0) AS total_order_value,
    COUNT(DISTINCT ho.o_orderkey) AS order_count
FROM 
    nation n
LEFT JOIN 
    RankedOrders ho ON n.n_nationkey = ho.c_nationkey AND ho.order_rank <= 5
LEFT JOIN 
    HighValueSuppliers hvs ON hvs.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey
            FROM lineitem l
            JOIN orders o ON l.l_orderkey = o.o_orderkey
            WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 5000
        )
    )
GROUP BY 
    n.n_name
ORDER BY 
    total_order_value DESC NULLS LAST
LIMIT 10;