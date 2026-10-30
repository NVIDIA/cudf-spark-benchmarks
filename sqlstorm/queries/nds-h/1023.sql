WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customers_count,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_sales,
    AVG(lo.l_quantity) AS avg_line_quantity,
    sp.total_availability,
    sp.avg_supply_cost
FROM 
    lineitem lo
LEFT JOIN 
    orders o ON lo.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON lo.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierPart sp ON lo.l_partkey = sp.ps_partkey
WHERE 
    (o.o_orderstatus = 'F' OR o.o_orderstatus = 'O') 
    AND lo.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01'
    AND (n.n_name IS NOT NULL OR sp.total_availability IS NULL)
GROUP BY 
    n.n_name, sp.total_availability, sp.avg_supply_cost
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 10000
ORDER BY 
    total_sales DESC;