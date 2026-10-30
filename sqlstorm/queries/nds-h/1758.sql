
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        COUNT(ps.ps_suppkey) AS number_of_suppliers,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name
    HAVING 
        COUNT(ps.ps_suppkey) > 5
)
SELECT 
    p.p_name,
    p.avg_supplycost,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    s.nation_name,
    s.s_name AS top_supplier,
    s.s_acctbal
FROM 
    PartSupplierInfo p
LEFT JOIN 
    OrderDetails l ON l.l_partkey = p.ps_partkey
LEFT JOIN 
    RankedSuppliers s ON s.s_suppkey = l.l_suppkey AND s.supplier_rank = 1
GROUP BY 
    p.p_name, p.avg_supplycost, s.nation_name, s.s_name, s.s_acctbal
HAVING 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > (SELECT AVG(total_spent) FROM TotalOrders)
ORDER BY 
    total_sales DESC, p.p_name;
