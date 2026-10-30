WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
), SupplierPartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    SUM(COALESCE(co.total_spent, 0)) AS total_spent_per_region,
    COUNT(DISTINCT ro.o_orderkey) AS orders_count,
    SUM(sp.total_available * sp.avg_supply_cost) AS total_inventory_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    SupplierPartInfo sp ON ps.ps_partkey = sp.p_partkey
LEFT JOIN 
    CustomerOrders co ON s.s_suppkey = co.c_custkey
LEFT JOIN 
    RankedOrders ro ON co.c_custkey = ro.o_orderkey
WHERE 
    (ro.order_rank <= 10 OR ro.order_rank IS NULL)
GROUP BY 
    r.r_name
HAVING 
    SUM(sp.total_available * sp.avg_supply_cost) IS NOT NULL
ORDER BY 
    total_spent_per_region DESC;