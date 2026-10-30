WITH RankedSales AS (
    SELECT 
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY p.p_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        p.p_name
), HighValueSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 100
    GROUP BY 
        s.s_name, s.s_nationkey
    HAVING 
        AVG(s.s_acctbal) > 5000
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) IS NULL OR SUM(o.o_totalprice) > 10000
)

SELECT 
    rh.p_name,
    rh.total_sales,
    hvs.s_name AS supplier_name,
    hvs.avg_acctbal,
    co.order_count,
    co.total_spent
FROM 
    RankedSales rh
LEFT JOIN 
    HighValueSuppliers hvs ON hvs.s_nationkey = (SELECT n.n_nationkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey LIMIT 1) 
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY c.c_acctbal DESC LIMIT 1) 
WHERE 
    rh.sales_rank <= 10
ORDER BY 
    rh.total_sales DESC
LIMIT 10 OFFSET 0;