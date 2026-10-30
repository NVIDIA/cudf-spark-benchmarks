WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name,
    cr.nation_name,
    COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS revenue,
    COUNT(DISTINCT lo.l_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY cr.region_name ORDER BY COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) DESC) AS rn,
    MAX(sd.total_supply_cost) AS max_supply_cost
FROM 
    lineitem lo
LEFT JOIN 
    RankedOrders ro ON lo.l_orderkey = ro.o_orderkey
INNER JOIN 
    CustomerRegion cr ON ro.o_custkey = cr.c_custkey
LEFT JOIN 
    SupplierDetails sd ON lo.l_suppkey = sd.s_suppkey
WHERE 
    lo.l_shipdate >= DATE '1997-01-01'
    AND (lo.l_discount BETWEEN 0.05 AND 0.20 OR lo.l_returnflag = 'N')
GROUP BY 
    cr.region_name, cr.nation_name
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 100000
ORDER BY 
    cr.region_name, revenue DESC;