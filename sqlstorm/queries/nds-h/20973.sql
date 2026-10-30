WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), 
SupplierPartInfo AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        p.p_partkey
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            WHEN o.o_orderstatus = 'P' THEN 'Pending'
            ELSE 'Other'
        END AS order_status,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderstatus
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
), 
ExpensiveOrders AS (
    SELECT 
        DISTINCT fo.o_orderkey,
        fo.total_revenue,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        FilteredOrders fo
    JOIN 
        lineitem l ON fo.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        fo.o_orderkey, fo.total_revenue
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
)
SELECT 
    n.n_name,
    COUNT(DISTINCT e.o_orderkey) AS outstanding_orders,
    AVG(e.total_revenue) AS avg_revenue_per_order
FROM 
    nation n
LEFT JOIN 
    SupplierPartInfo spi ON spi.supplier_count > 3
LEFT JOIN 
    ExpensiveOrders e ON e.part_count > 10
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
WHERE 
    n.n_nationkey IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    AVG(e.total_revenue) IS NULL OR AVG(e.total_revenue) > 10000
ORDER BY 
    outstanding_orders DESC, n.n_name ASC;
