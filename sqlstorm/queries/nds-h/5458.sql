
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
FrequentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate <= DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT hc.c_custkey) AS high_value_customer_count,
    SUM(CASE WHEN rs.rn <= 3 THEN 1 ELSE 0 END) AS top_suppliers_count,
    COUNT(DISTINCT fo.o_orderkey) AS frequent_order_count,
    AVG(fo.total_revenue) AS avg_frequent_order_revenue,
    SUM(sp.supplier_count) AS parts_count_by_supplier
FROM 
    RankedSuppliers rs
JOIN 
    region r ON rs.rn <= 3
JOIN 
    HighValueCustomers hc ON hc.order_count > 0
JOIN 
    FrequentOrders fo ON fo.total_revenue > 1000
JOIN 
    SupplierParts sp ON sp.ps_partkey = rs.s_suppkey
GROUP BY 
    r.r_name
ORDER BY 
    region_name;
