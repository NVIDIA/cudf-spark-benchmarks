WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        p.p_name, 
        p.p_brand, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        p.p_name, 
        p.p_brand, 
        s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_name, 
        SUM(sp.supplier_cost) AS total_supplier_cost
    FROM 
        SupplierPartDetails sp
    JOIN 
        supplier s ON sp.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_name
    ORDER BY 
        total_supplier_cost DESC
    LIMIT 5
)
SELECT 
    R.r_name AS region_name, 
    T.s_name AS supplier_name, 
    T.total_supplier_cost,
    R.r_comment,
    COUNT(DISTINCT O.o_orderkey) AS order_count,
    SUM(RO.total_revenue) AS total_revenue
FROM 
    TopSuppliers T
JOIN 
    supplier S ON T.s_name = S.s_name
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
JOIN 
    orders O ON O.o_custkey = N.n_nationkey  
JOIN 
    RankedOrders RO ON O.o_orderkey = RO.o_orderkey
GROUP BY 
    R.r_name, 
    T.s_name, 
    T.total_supplier_cost, 
    R.r_comment
ORDER BY 
    total_revenue DESC, 
    order_count DESC;