WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COALESCE(sc.total_cost, 0) AS supplier_total_cost,
    COALESCE(os.total_revenue, 0) AS order_total_revenue,
    os.item_count,
    (CASE 
        WHEN os.total_revenue > 100000 THEN 'High Revenue'
        WHEN os.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END) AS revenue_category
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierCost sc ON s.s_suppkey = sc.s_suppkey
LEFT JOIN 
    OrderSummary os ON s.s_suppkey = os.o_custkey
WHERE 
    (sc.total_cost IS NOT NULL OR os.total_revenue IS NOT NULL)
    AND s.s_acctbal IS NOT NULL
ORDER BY 
    region_name, nation_name, supplier_name;