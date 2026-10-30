WITH OrderAggregates AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(s.total_avail_qty, 0) AS available_quantity,
    COALESCE(s.total_supply_cost, 0) AS supply_cost,
    o.total_revenue,
    o.total_quantity,
    o.customer_count,
    CASE 
        WHEN o.total_revenue IS NULL THEN 'No Sales'
        WHEN o.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    part p
LEFT JOIN 
    SupplierParts s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    OrderAggregates o ON p.p_partkey = o.o_orderkey
ORDER BY 
    revenue_category DESC, 
    total_revenue DESC
LIMIT 100
OFFSET 0;