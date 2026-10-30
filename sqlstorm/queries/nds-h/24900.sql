
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
QualifiedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
SupplierRegion AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        SUM(ps.ps_supplycost) AS region_supplier_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        r.r_name LIKE 'E%' OR r.r_comment IS NOT NULL
    GROUP BY 
        n.n_nationkey, r.r_regionkey
)

SELECT 
    q.o_orderkey,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    q.total_revenue,
    q.item_count,
    COALESCE(sr.region_supplier_cost, 0) AS regional_cost,
    CASE 
        WHEN q.item_count > 10 THEN 'High Volume'
        WHEN q.item_count BETWEEN 5 AND 10 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    DENSE_RANK() OVER (ORDER BY q.total_revenue DESC) AS revenue_rank
FROM 
    QualifiedOrders q
LEFT JOIN 
    RankedSuppliers r ON q.o_custkey = r.s_suppkey 
LEFT JOIN 
    SupplierRegion sr ON r.rank_cost < 5 AND sr.n_nationkey = q.o_custkey % (SELECT COUNT(*) FROM nation) 
WHERE 
    q.total_revenue > 1000
ORDER BY 
    revenue_rank, supplier_name;
