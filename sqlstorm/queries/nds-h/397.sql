WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_available, 
        ss.total_cost, 
        ss.part_count,
        RANK() OVER (ORDER BY ss.total_cost DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_available > 1000
)
SELECT 
    ts.s_name,
    ts.total_available,
    ts.total_cost,
    ts.part_count,
    od.revenue AS order_revenue,
    CASE 
        WHEN od.revenue IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderDetails od ON ts.s_suppkey = od.o_orderkey
WHERE 
    ts.rnk <= 10
ORDER BY 
    ts.total_cost DESC, ts.s_name;