WITH SupplierCosts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        sc.total_cost,
        sc.order_count,
        ROW_NUMBER() OVER (ORDER BY sc.total_cost DESC) AS rn
    FROM 
        supplier s
    LEFT JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
)
SELECT 
    t.s_suppkey,
    t.s_name,
    COALESCE(t.total_cost, 0) AS total_cost,
    COALESCE(t.order_count, 0) AS order_count,
    CASE 
        WHEN t.total_cost IS NULL THEN 'No Orders'
        WHEN t.order_count > 1 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS order_type
FROM 
    TopSuppliers t
WHERE 
    t.rn <= 10
ORDER BY 
    total_cost DESC;