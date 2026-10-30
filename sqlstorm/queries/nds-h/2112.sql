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
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), CustomerWithHighOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
)
SELECT 
    p.p_name,
    p.p_brand,
    r.r_name,
    RankedSuppliers.s_name AS top_supplier,
    HighValueOrders.o_orderdate,
    HighValueOrders.total_revenue,
    CustomerWithHighOrders.c_name,
    CustomerWithHighOrders.total_spent
FROM 
    part p
LEFT JOIN 
    RankedSuppliers ON p.p_partkey = RankedSuppliers.s_suppkey AND RankedSuppliers.rn = 1
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueOrders ON p.p_partkey = HighValueOrders.o_orderkey
LEFT JOIN 
    CustomerWithHighOrders ON HighValueOrders.o_orderkey = CustomerWithHighOrders.order_count
WHERE 
    p.p_retailprice IS NOT NULL
    AND (p.p_size BETWEEN 10 AND 20 OR p.p_type LIKE '%metal%')
ORDER BY 
    HighValueOrders.total_revenue DESC, CustomerWithHighOrders.total_spent ASC
LIMIT 50;
