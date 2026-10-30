
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), NationalSuppliers AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT sd.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
), OrderSummary AS (
    SELECT 
        r.r_name AS region_name, 
        ra.o_orderkey,
        ra.total_revenue,
        ns.supplier_count
    FROM 
        RankedOrders ra
    JOIN 
        customer c ON ra.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        NationalSuppliers ns ON n.n_nationkey = ns.n_nationkey
    WHERE 
        ra.total_revenue > (SELECT AVG(total_revenue) FROM RankedOrders)
)
SELECT 
    region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(o.total_revenue) AS total_revenue,
    AVG(o.supplier_count) AS average_supplier_count
FROM 
    OrderSummary o
GROUP BY 
    region_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
