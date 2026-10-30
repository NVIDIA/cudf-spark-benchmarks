WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-10-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_brand,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_brand
)
SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(sp.avg_supplycost) AS average_supply_cost,
    MIN(RO.order_rank) AS min_order_rank
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    SupplierParts sp ON l.l_partkey = sp.ps_partkey
JOIN 
    RankedOrders RO ON o.o_orderkey = RO.o_orderkey
WHERE 
    o.o_orderstatus = 'F'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_revenue DESC, total_quantity DESC
LIMIT 10;