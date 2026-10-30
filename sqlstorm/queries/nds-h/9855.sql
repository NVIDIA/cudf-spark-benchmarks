WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1998-01-01' AND o.o_orderdate < DATE '1998-12-31'
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT s.s_name) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_type,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    r.r_name AS region_name,
    MAX(sup.total_cost) AS max_supplier_cost,
    AVG(sup.total_cost) AS avg_supplier_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierPartDetails sup ON p.p_partkey = sup.ps_partkey
WHERE 
    o.o_orderstatus = 'F' AND
    l.l_shipdate >= DATE '1998-01-01' AND
    l.l_shipdate < DATE '1998-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 AND
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC, customer_count DESC;
