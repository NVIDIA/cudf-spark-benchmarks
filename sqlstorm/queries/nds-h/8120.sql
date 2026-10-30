WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplierPartCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) as total_supplycost
    FROM 
        partsupp ps
    INNER JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name,
    n.n_name,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(spc.total_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS total_customers_involved
FROM 
    lineitem lo
INNER JOIN 
    orders o ON lo.l_orderkey = o.o_orderkey
INNER JOIN 
    customer c ON o.o_custkey = c.c_custkey
INNER JOIN 
    supplier s ON lo.l_suppkey = s.s_suppkey
INNER JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
INNER JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierPartCosts spc ON lo.l_partkey = spc.ps_partkey
WHERE 
    lo.l_shipdate >= DATE '1997-03-01' AND lo.l_shipdate < DATE '1997-03-31'
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, total_orders DESC;