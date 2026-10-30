WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(roi.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        RankedOrders roi ON n.n_nationkey = roi.c_nationkey
    WHERE 
        roi.rank_order <= 5
    GROUP BY 
        n.n_nationkey, n.n_name
),
SupplierPartCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    tp.total_revenue,
    spc.total_supply_cost
FROM 
    part p
JOIN 
    SupplierPartCost spc ON p.p_partkey = spc.ps_partkey
JOIN 
    TopNations tp ON tp.total_revenue > (SELECT AVG(total_revenue) FROM TopNations)
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
ORDER BY 
    tp.total_revenue DESC, spc.total_supply_cost ASC
LIMIT 10;
