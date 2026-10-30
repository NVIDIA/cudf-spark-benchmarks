WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice,
        CASE 
            WHEN o.o_totalprice > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS order_value_category
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
        AND (o.o_totalprice IS NOT NULL OR o.o_totalprice < 2000)
), SupplierPartSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
) 
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT CASE WHEN s.rn = 1 THEN s.s_suppkey END) AS top_supplier_count,
    MAX(sp.total_available) AS max_available_quantity,
    ROUND(AVG(sp.avg_supply_cost), 2) AS avg_supply_cost_summary
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = l.l_suppkey 
LEFT JOIN 
    SupplierPartSummary sp ON sp.ps_partkey = l.l_partkey 
WHERE 
    r.r_name LIKE 'E%' 
    AND (c.c_acctbal BETWEEN 1000 AND 1000000 OR c.c_acctbal IS NULL)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0 
    AND AVG(o.o_totalprice) IS NOT NULL
ORDER BY 
    total_revenue DESC, max_available_quantity ASC;
