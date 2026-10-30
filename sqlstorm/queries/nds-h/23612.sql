
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_availqty) AS distinct_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
NationalSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name IN ('USA', 'Germany')
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ss.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(rs.total_revenue, 0) AS total_revenue,
    ns.supplier_count,
    (CASE 
        WHEN ss.distinct_avail_qty IS NULL THEN 'No Stock' 
        WHEN ss.distinct_avail_qty > 10 THEN 'Well Stocked' 
        ELSE 'Low Stock' 
    END) AS stock_status
FROM 
    part p
LEFT JOIN 
    SupplierStats ss ON p.p_partkey = ss.ps_partkey
FULL OUTER JOIN 
    RankedOrders rs ON rs.o_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY o.o_orderdate DESC LIMIT 1) 
LEFT JOIN 
    NationalSuppliers ns ON ns.n_nationkey = (SELECT DISTINCT n.n_nationkey FROM nation n WHERE n.n_name = 'USA' LIMIT 1)
WHERE 
    (p.p_size BETWEEN 1 AND 25 OR p.p_container IS NULL)
    AND (p.p_brand <> 'Brand#23' OR p.p_comment LIKE '%special%')
ORDER BY 
    total_revenue DESC, p.p_partkey ASC;
