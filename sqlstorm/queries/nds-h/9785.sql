WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    o.total_quantity,
    o.total_revenue,
    ns.n_name AS supplier_nation,
    ps.p_name AS part_name,
    ps.total_available,
    ps.avg_supplycost
FROM 
    OrderSummary o
JOIN 
    NationSupplier ns ON o.o_orderkey % 10 = ns.n_nationkey 
JOIN 
    PartSupplier ps ON o.o_orderkey % 5 = ps.ps_partkey 
ORDER BY 
    o.o_orderdate DESC, total_revenue DESC
LIMIT 100;