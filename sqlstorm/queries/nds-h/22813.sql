
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderstatus = 'F'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighlyRatedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) FROM supplier s2
        )
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    np.n_name AS supplier_nation,
    s.s_name AS supplier_name,
    COALESCE(sp.total_avail_qty, 0) AS available_quantity,
    COALESCE(sp.avg_supply_cost, 0) AS avg_cost,
    CASE 
        WHEN ro.price_rank = 1 THEN 'Top'
        WHEN ro.price_rank <= 3 THEN 'High'
        ELSE 'Regular'
    END AS order_pricing_category
FROM 
    RankedOrders ro
LEFT JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    SupplierParts sp ON l.l_partkey = sp.ps_partkey
JOIN 
    supplier s ON sp.ps_suppkey = s.s_suppkey
JOIN 
    nation np ON s.s_nationkey = np.n_nationkey
WHERE 
    (sp.avg_supply_cost IS NULL OR sp.avg_supply_cost < 100) 
    AND ro.o_totalprice BETWEEN 100 AND 10000
ORDER BY 
    ro.o_orderdate DESC, 
    order_pricing_category, 
    available_quantity DESC;
