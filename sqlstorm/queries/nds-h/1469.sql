
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_nationkey
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rnk <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
RevenueAnalysis AS (
    SELECT 
        c.c_name,
        COALESCE(SUM(co.total_revenue), 0) AS customer_revenue
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    ra.c_name,
    ra.customer_revenue,
    CASE 
        WHEN ra.customer_revenue > 10000 THEN 'High'
        WHEN ra.customer_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_classification
FROM 
    RevenueAnalysis ra
JOIN 
    TopSuppliers ts ON ts.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
ORDER BY 
    ra.customer_revenue DESC;
