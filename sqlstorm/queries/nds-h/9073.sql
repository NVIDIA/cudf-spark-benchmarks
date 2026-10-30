
WITH PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        s.s_nationkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(oi.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        OrderInfo oi ON c.c_custkey = oi.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    psi.p_partkey,
    psi.p_name,
    psi.supplier_name,
    oi.total_revenue,
    cr.customer_revenue,
    ROW_NUMBER() OVER (PARTITION BY cr.c_custkey ORDER BY cr.customer_revenue DESC) AS revenue_rank
FROM 
    PartSupplierInfo psi
JOIN 
    OrderInfo oi ON psi.p_partkey = oi.o_orderkey
JOIN 
    CustomerRevenue cr ON oi.o_custkey = cr.c_custkey
WHERE 
    psi.ps_supplycost < 50
ORDER BY 
    cr.customer_revenue DESC
LIMIT 100;
